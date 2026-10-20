import AppKit
import Combine
import QuartzCore
import SwiftUI

/// Owns the overlay's frame, timed notices, and interruptible dismissal.
@MainActor
final class DictationPanelController: NSObject {
    private static let edgeInset: CGFloat = 24
    private let panel: DictationPanel
    private let hosting: NSHostingView<ThemedRoot<DictationPanelView>>
    private let presentation: OverlayPresentation
    private let model: AppModel
    private let timing: OverlayTiming
    private let reduceMotion: () -> Bool
    private var phaseObserver: AnyCancellable?
    private var meterObserver: AnyCancellable?
    private var hideTimer: Timer?
    private var generation = 0

    var isVisible: Bool { panel.isVisible }
    var isExiting: Bool { presentation.exiting }
    var opacity: CGFloat { panel.alphaValue }
    var displayedState: DictationOverlayState { presentation.state }
    var frame: NSRect { panel.frame }
    private(set) var targetFrame: NSRect = .zero

    #if DEBUG
    /// Promo capture only. A fixed screen for the panel, so framing does not follow the pointer.
    /// nil keeps the production behavior.
    var promoScreen: NSScreen?

    /// Promo capture only. Feeds meter values into a displayed recording state.
    /// It does not change the model, resize the panel, or restart timers.
    func promoSetMeter(elapsed: TimeInterval, level: Float) {
        guard case .recording = presentation.state, !presentation.exiting else { return }
        presentation.state = .recording(elapsed: elapsed, level: level)
    }
    #endif

    init(model: AppModel, timing: OverlayTiming = OverlayTiming(),
         reduceMotion: @escaping () -> Bool = { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }) {
        self.model = model
        self.timing = timing
        self.reduceMotion = reduceMotion
        let presentation = OverlayPresentation()
        self.presentation = presentation
        panel = DictationPanel()
        hosting = NSHostingView(rootView: ThemedRoot(preferences: model.preferences) {
            DictationPanelView(presentation: presentation, actions: .preview, timing: timing)
        })
        super.init()
        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        hosting.rootView = ThemedRoot(preferences: model.preferences) {
            DictationPanelView(presentation: presentation, actions: actions, timing: timing)
        }
        panel.contentView = hosting
        phaseObserver = model.$phase.dropFirst().sink { [weak self] phase in
            self?.update(for: phase)
        }
        meterObserver = model.$elapsed.combineLatest(model.$level).sink { [weak self] elapsed, level in
            guard let self, self.model.phase == .recording,
                  case .recording(let previous, _) = self.presentation.state, elapsed >= previous else { return }
            self.presentation.state = .recording(elapsed: elapsed, level: level)
        }
        update(for: model.phase)
    }

    /// Called once per operation phase. Meter ticks update content without resizing or restarting timers.
    func update(for phase: DictationPhase) {
        generation += 1
        cancelTimer()
        if phase == .idle {
            hide()
            return
        }
        let state = DictationOverlayState(phase: phase, elapsed: model.elapsed, level: model.level,
                                         manualPasteHelpDismissed: model.preferences.manualPasteHelpDismissed)
        show(state)
        if let hold = timing.hold(for: state) {
            let timer = Timer(timeInterval: hold, target: self, selector: #selector(hideTimerFired(_:)),
                              userInfo: nil, repeats: false)
            hideTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func dismissHelp() {
        guard presentation.state.isHelp else { return }
        model.preferences.manualPasteHelpDismissed = true
        generation += 1
        cancelTimer()
        hide()
    }

    func shutdown() {
        generation += 1
        cancelTimer()
        phaseObserver?.cancel()
        meterObserver?.cancel()
        panel.orderOut(nil)
        presentation.state = .hidden
        presentation.exiting = false
    }

    private var actions: DictationOverlayActions {
        DictationOverlayActions(stop: { [weak model] in model?.stopDictation() },
                                 cancel: { [weak model] in
                                     guard let model, model.phase.canCancel else { return }
                                     model.cancel()
                                 },
                                 dismiss: { [weak self] in self?.dismissHelp() })
    }

    @objc private func hideTimerFired(_ timer: Timer) {
        guard timer === hideTimer else { return }
        hideTimer = nil
        if presentation.state.isHelp { model.preferences.manualPasteHelpDismissed = true }
        hide()
    }

    private func cancelTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    private func show(_ state: DictationOverlayState) {
        let wasVisible = panel.isVisible
        let size = measure(state)
        let mouse = NSEvent.mouseLocation
        #if DEBUG
        let preferredScreen = promoScreen
        #else
        let preferredScreen: NSScreen? = nil
        #endif
        let screen = wasVisible ? panel.screen
            : preferredScreen ?? NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
        let y = model.preferences.overlayPlacement == .top
            ? visible.maxY - Self.edgeInset - size.height : visible.minY + Self.edgeInset
        targetFrame = NSRect(x: visible.midX - size.width / 2, y: y, width: size.width, height: size.height)
        presentation.exiting = false
        presentation.state = state

        let reduced = reduceMotion()
        if wasVisible && !reduced {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = timing.resize
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(targetFrame, display: true)
                panel.animator().alphaValue = 1
            }
        } else {
            panel.setFrame(targetFrame, display: true)
            if !wasVisible { panel.alphaValue = 0 }
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = reduced ? timing.reducedFade : timing.entrance
                panel.animator().alphaValue = 1
            }
        }
        if let announcement = state.announcement {
            NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested,
                                 userInfo: [.announcement: announcement,
                                            .priority: NSAccessibilityPriorityLevel.high.rawValue])
        }
    }

    private func measure(_ state: DictationOverlayState) -> NSSize {
        let view = NSHostingView(rootView: ThemedRoot(preferences: model.preferences) {
            DictationOverlayView(state: state, actions: .preview)
        })
        view.layoutSubtreeIfNeeded()
        let size = view.fittingSize
        return NSSize(width: ceil(size.width), height: ceil(size.height))
    }

    private func hide() {
        guard panel.isVisible else { return }
        let current = generation
        presentation.exiting = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion() ? timing.reducedFade : timing.exit
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            DispatchQueue.main.async {
                self?.finishHide(generation: current)
            }
        }
    }

    private func finishHide(generation: Int) {
        guard self.generation == generation, presentation.exiting else { return }
        panel.orderOut(nil)
        presentation.state = .hidden
        presentation.exiting = false
    }
}
