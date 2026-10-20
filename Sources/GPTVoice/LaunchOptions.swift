import Foundation

/// How the GUI app starts.
enum LaunchOptions: Equatable {
    case normal
    case showOnboarding
    case showSettings
    /// Test path: transcribe a supplied file and deliver it. Skips automatic setup windows.
    case transcribeAndPaste(URL)
    /// Test path: show a real file transcription in onboarding without changing the clipboard.
    case practiceAudio(URL)

    /// The distributed notification a duplicate launch posts to the running instance.
    static let showSettingsNotification = Notification.Name("com.vishesh.codex-dictation.show-settings")
    static let showOnboardingNotification = Notification.Name("com.vishesh.codex-dictation.show-onboarding")
}
