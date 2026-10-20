import SwiftUI

/// Welcome in three zones: what it does, a small demonstration with the real keys and bar, and the ChatGPT row.
struct OnboardingWelcomeStep: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences

    init(model: AppModel) {
        self.model = model
        self.preferences = model.preferences
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            OnboardingHeader(title: "Dictate into any app",
                             summary: "Press your shortcut, speak, and press it again.")

            HStack(spacing: 14) {
                KeycapsView(spec: preferences.hotkey)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                DictationOverlayView(state: .recording(elapsed: 4, level: 0.5), actions: .preview)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sample: press \(preferences.hotkey.accessibilityLabel) and the recording bar appears.")

            VStack(alignment: .leading, spacing: 8) {
                SettingsGroup {
                    ConnectionPanel(model: model, prominentSignIn: true)
                }
                Text("Audio is sent to ChatGPT for transcription.")
                    .font(AppType.detail)
                    .foregroundStyle(.secondary)
                InfoDisclosure(label: "Storage and account",
                               text: "Recordings are temporary files. No transcript history is saved. Sign-in is shared with Codex CLI, and this app makes no copy of your credentials.")
            }
        }
    }
}
