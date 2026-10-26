import AppKit
import Combine

/// The always-visible menu bar item. Rebuilds its menu from model state each time it opens.
/// Opening the menu does not activate the app, so the paste target stays frontmost.
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let model: AppModel
    private let windows: WindowCoordinator
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private var phaseObserver: AnyCancellable?

    init(model: AppModel, windows: WindowCoordinator) {
        self.model = model
        self.windows = windows
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        menu = NSMenu()
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        statusItem.isVisible = true
        updateIcon(for: model.phase)
        phaseObserver = model.$phase
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in self?.updateIcon(for: phase) }
    }

    private func updateIcon(for phase: DictationPhase) {
        let symbol: String
        let description: String
        switch phase {
        case .recording: symbol = "mic.fill"; description = "GPT Voice, listening"
        case .preparing, .transcribing, .pasting: symbol = "mic.circle"; description = "GPT Voice, working"
        case .failed: symbol = "mic.slash"; description = "GPT Voice, needs attention"
        case .idle, .finished: symbol = "mic"; description = "GPT Voice"
        }
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
            ?? NSImage(systemSymbolName: "mic", accessibilityDescription: description)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = description
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.refreshStatus()
        menu.removeAllItems()

        let status = NSMenuItem(title: model.statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        if let error = model.hotkeyError {
            let problem = NSMenuItem(title: error, action: nil, keyEquivalent: "")
            problem.isEnabled = false
            menu.addItem(problem)
            if model.hotkeyNeedsInputMonitoring {
                menu.addItem(item("Input Monitoring Settings…", #selector(openInputMonitoring), enabled: true))
            }
        }
        menu.addItem(.separator())

        let recording = model.phase == .recording
        let toggle = item(recording ? "Stop Dictation" : "Start Dictation", #selector(toggleDictation),
                          enabled: recording || model.canStart)
        if let key = model.hotkey.menuKeyEquivalent {
            toggle.keyEquivalent = key
            toggle.keyEquivalentModifierMask = model.hotkey.cocoaModifiers
        } else {
            toggle.title += "  (\(model.hotkey.displayLabel))"
        }
        menu.addItem(toggle)
        if model.phase.canCancel {
            menu.addItem(item("Cancel", #selector(cancel), enabled: true))
        }
        if model.canRetry {
            menu.addItem(item("Retry", #selector(retry), enabled: true))
        }
        menu.addItem(.separator())
        let hasTranscript = model.lastTranscript != nil
        menu.addItem(item("Paste Last Transcript", #selector(pasteLast), enabled: hasTranscript && model.canStart))
        menu.addItem(item("Copy Last Transcript", #selector(copyLast), enabled: hasTranscript))
        menu.addItem(.separator())
        let settings = item("Settings…", #selector(showSettings), enabled: true)
        settings.keyEquivalent = ","
        menu.addItem(settings)
        menu.addItem(item("Run Setup Again…", #selector(showOnboarding), enabled: true))
        menu.addItem(.separator())
        let quit = item("Quit GPT Voice", #selector(quit), enabled: true)
        quit.keyEquivalent = "q"
        menu.addItem(quit)
    }

    private func item(_ title: String, _ action: Selector, enabled: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        return item
    }

    @objc private func toggleDictation() { model.toggleDictation() }
    @objc private func cancel() { model.cancel() }
    @objc private func retry() { model.retry() }
    @objc private func pasteLast() { model.pasteLastTranscript() }
    @objc private func copyLast() { model.copyLastTranscript() }
    @objc private func showSettings() { windows.showSettings() }
    @objc private func openInputMonitoring() { model.openInputMonitoringSettings() }
    @objc private func showOnboarding() { windows.showOnboarding() }
    @objc private func quit() { NSApp.terminate(nil) }
}
