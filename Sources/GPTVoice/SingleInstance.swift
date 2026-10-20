import AppKit

/// Prevents a second GUI instance from registering a second shortcut.
enum SingleInstance {
    /// Returns true when another instance runs. It then receives a request to show a window.
    static func forwardToRunningInstance(_ options: LaunchOptions) -> Bool {
        if case .transcribeAndPaste = options { return false }
        if case .practiceAudio = options { return false }
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ownPID && !$0.isTerminated }
        guard !others.isEmpty else { return false }
        let name = options == .showOnboarding
            ? LaunchOptions.showOnboardingNotification
            : LaunchOptions.showSettingsNotification
        DistributedNotificationCenter.default().postNotificationName(name, object: nil, userInfo: nil,
                                                                     deliverImmediately: true)
        return true
    }
}
