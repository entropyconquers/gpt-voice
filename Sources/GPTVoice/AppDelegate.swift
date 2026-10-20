import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let options: LaunchOptions
    private let model: AppModel
    private let windows: WindowCoordinator
    private var statusMenu: StatusMenuController?
    private var panel: DictationPanelController?
    private var appearance: AppearanceController?
    private var verificationTrace: VerificationTrace?
    private var observers: [NSObjectProtocol] = []

    init(options: LaunchOptions) {
        self.options = options
        model = AppModel()
        windows = WindowCoordinator(model: model)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = MainMenuBuilder.make()
        appearance = AppearanceController(preferences: model.preferences)
        statusMenu = StatusMenuController(model: model, windows: windows)
        panel = DictationPanelController(model: model)
        model.activate()
        model.refreshStatus()
        observeOtherLaunches()

        switch options {
        case .showOnboarding:
            windows.showOnboarding()
        case .showSettings:
            windows.showSettings()
        case .transcribeAndPaste(let url):
            verificationTrace = VerificationTrace(model: model)
            if let expected = ProcessInfo.processInfo.environment["CODEX_DICTATION_EXPECT_TARGET"],
               NSWorkspace.shared.frontmostApplication?.bundleIdentifier != expected {
                FileHandle.standardError.write(Data("Verification stopped: the expected target app is not in front.\n".utf8))
                NSApp.terminate(nil)
                return
            }
            model.transcribeFile(url)
        case .practiceAudio(let url):
            verificationTrace = VerificationTrace(model: model)
            model.transcribeFile(url, forPractice: true)
            windows.showOnboarding()
        case .normal:
            if !model.preferences.onboardingCompleted { windows.showOnboarding() }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.refreshStatus()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windows.showSettings()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Waits for a pending clipboard restore so the old clipboard returns before quitting.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.isPasteLeasePending || model.phase == .pasting || model.history.isUpdating else {
            model.cleanup()
            return .terminateNow
        }
        Task {
            await model.waitForDeliveryAndHistory()
            model.cleanup()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    private func observeOtherLaunches() {
        let center = DistributedNotificationCenter.default()
        observers.append(center.addObserver(forName: LaunchOptions.showSettingsNotification, object: nil,
                                            queue: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.windows.showSettings() }
        })
        observers.append(center.addObserver(forName: LaunchOptions.showOnboardingNotification, object: nil,
                                            queue: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.windows.showOnboarding() }
        })
    }
}
