import AppKit
import Carbon.HIToolbox

/// A focusable control that records one modifier+key shortcut.
/// Click it, or focus it and press Space or Return, to start. Esc cancels.
final class ShortcutRecorderNSView: NSView {
    var onBegin: () -> Void = {}
    var onEnd: () -> Void = {}
    /// Returns true when the shortcut was saved.
    var onCapture: (HotkeySpec) -> Bool = { _ in false }
    var onProblem: (HotkeySpec.Problem) -> Void = { _ in }
    var currentLabel = "" { didSet { updateAccessibility() } }
    var accentColor: NSColor = .controlAccentColor { didSet { needsDisplay = true } }
    var isEnabled = true {
        didSet {
            if !isEnabled { stopRecording() }
            needsDisplay = true
        }
    }

    private(set) var isRecording = false {
        didSet {
            needsDisplay = true
            updateAccessibility()
        }
    }
    private var observers: [NSObjectProtocol] = []
    /// Modifier key held alone while recording. Captured on release.
    private var pendingTap: UInt32?
    /// Device-dependent modifier bits at the previous flags event.
    private var recordedDeviceFlags: UInt = 0
    private static let radius: CGFloat = 6

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        focusRingType = .default
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Keyboard shortcut recorder")
        updateAccessibility()
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: NSSize { NSSize(width: 220, height: 28) }
    override var acceptsFirstResponder: Bool { isEnabled }
    override var canBecomeKeyView: Bool { isEnabled }
    override var focusRingMaskBounds: NSRect { bounds }

    override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
    }

    /// Rounded-rectangle painting (radius 8). Idle: recessed well. Recording: light accent wash and a 2 pt accent edge.
    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let radius: CGFloat = 8
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        AppPalette.nsWell.setFill()
        path.fill()
        if isRecording {
            accentColor.withAlphaComponent(0.08).setFill()
            path.fill()
        }
        (isRecording ? accentColor : NSColor.separatorColor.withAlphaComponent(0.4)).setStroke()
        path.lineWidth = isRecording ? 2 : 1
        path.stroke()

        let text = isRecording ? "Press keys, or hold Option. Esc cancels." : "Click to record"
        let color: NSColor = !isEnabled ? .tertiaryLabelColor : (isRecording ? .labelColor : .secondaryLabelColor)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: AppType.nsControlSmall,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let height = string.size().height
        string.draw(in: NSRect(x: 8, y: (bounds.height - height) / 2, width: bounds.width - 16, height: height))
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        window?.makeFirstResponder(self)
        startRecording()
    }

    override func accessibilityPerformPress() -> Bool {
        guard isEnabled else { return false }
        window?.makeFirstResponder(self)
        startRecording()
        return true
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }
        let raw = UInt(event.modifierFlags.rawValue)
        let current = raw & HotkeySpec.deviceModifierMasks
        let changed = recordedDeviceFlags ^ current
        recordedDeviceFlags = current
        guard changed != 0, changed & (changed - 1) == 0 else {
            if changed != 0 { pendingTap = nil }
            return
        }
        let code = HotkeySpec.keyCode(forDeviceMask: changed)
        let down = current & changed != 0
        guard down else {
            guard pendingTap == code else { return }
            pendingTap = nil
            let spec = HotkeySpec(keyCode: code, modifiers: 0)
            if let problem = spec.problem {
                onProblem(problem)
                return
            }
            if onCapture(spec) { stopRecording() }
            return
        }
        if HotkeySpec.isSoleDeviceModifier(keyCode: code, rawFlags: raw),
           HotkeySpec.tappableModifierKeyCodes.contains(code) {
            pendingTap = code
        } else {
            pendingTap = nil
            if HotkeySpec.isSoleDeviceModifier(keyCode: code, rawFlags: raw) {
                onProblem(.modifierOnly)
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let plain = flags.intersection([.command, .option, .control, .shift]).isEmpty
        guard isRecording else {
            if plain, [kVK_Space, kVK_Return].contains(Int(event.keyCode)) {
                startRecording()
            } else if plain, Int(event.keyCode) == kVK_Tab {
                window?.selectNextKeyView(self)
            } else {
                super.keyDown(with: event)
            }
            return
        }
        handle(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording, window?.firstResponder === self else { return super.performKeyEquivalent(with: event) }
        handle(event)
        return true
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        stopRecording()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        for name in [NSWindow.didResignKeyNotification, NSWindow.willCloseNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) {
                [weak self] _ in self?.stopRecording()
            })
        }
    }

    private func handle(_ event: NSEvent) {
        pendingTap = nil
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if Int(event.keyCode) == kVK_Escape, flags.intersection([.command, .option, .control, .shift]).isEmpty {
            stopRecording()
            return
        }
        let spec = HotkeySpec(keyCode: event.keyCode, cocoaModifiers: flags)
        if let problem = spec.problem {
            onProblem(problem)
            return
        }
        if onCapture(spec) { stopRecording() }
    }

    private func startRecording() {
        guard isEnabled, !isRecording else { return }
        recordedDeviceFlags = UInt(NSEvent.modifierFlags.rawValue) & HotkeySpec.deviceModifierMasks
        pendingTap = nil
        isRecording = true
        onBegin()
    }

    private func stopRecording() {
        pendingTap = nil
        recordedDeviceFlags = 0
        guard isRecording else { return }
        isRecording = false
        onEnd()
    }

    private func updateAccessibility() {
        setAccessibilityValue(isRecording ? "Recording. Press a shortcut, or Esc to cancel." : currentLabel)
        setAccessibilityHelp("Records a new keyboard shortcut for dictation.")
    }
}
