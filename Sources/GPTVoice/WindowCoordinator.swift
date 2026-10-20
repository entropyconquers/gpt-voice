import AppKit

/// Owns the setup and settings windows. One of each at a time.
@MainActor
final class WindowCoordinator {
    private let model: AppModel
    private var onboarding: HostingWindowController?
    private var settings: HostingWindowController?

    init(model: AppModel) {
        self.model = model
    }

    func showOnboarding() {
        if let onboarding { onboarding.present(); return }
        let view = ThemedRoot(preferences: model.preferences) {
            OnboardingView(model: model) { [weak self] in
                self?.onboarding?.close()
            }
        }
        let controller = HostingWindowController(title: "Set Up GPT Voice", size: NSSize(width: 660, height: 520),
                                                 minSize: NSSize(width: 600, height: 480),
                                                 rootView: view) { [weak self] in self?.windowClosed(isSettings: false) }
        onboarding = controller
        controller.present()
    }

    func showSettings() {
        if let settings { settings.present(); return }
        let controller = HostingWindowController(title: "GPT Voice Settings", size: NSSize(width: 820, height: 600),
                                                 minSize: NSSize(width: 720, height: 540),
                                                 rootView: ThemedRoot(preferences: model.preferences) {
                                                     SettingsView(model: model)
                                                 }) { [weak self] in
            self?.windowClosed(isSettings: true)
        }
        settings = controller
        controller.present()
    }

    private func windowClosed(isSettings: Bool) {
        if model.isCapturingShortcut { model.endShortcutCapture() }
        model.endShortcutTest()
        // Closing setup stops any practice recording. It never affects a normal dictation.
        if !isSettings { model.endPractice() }
        if isSettings { settings = nil } else { onboarding = nil }
    }
}
