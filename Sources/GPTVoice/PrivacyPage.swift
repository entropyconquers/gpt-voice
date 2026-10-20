import SwiftUI

/// Privacy: four concise facts with labelled details, actionable permissions, then About.
struct PrivacyPage: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(title: "Your data") {
                fact("Audio", "Sent to ChatGPT for transcription.")
                fact("Recordings", "Temporary files on this Mac.",
                     details: "Deleted after a successful transcription or Cancel. A failed recording is kept for Retry until you quit.")
                fact("Transcripts", "Saved on this Mac. Delete any or all in History.")
                fact("Sign-in", "Shared with Codex CLI.",
                     details: "Credentials stay in Codex CLI storage. This app makes no copy. To sign out, run “codex logout” in Terminal. This also signs out Codex CLI.",
                     last: true)
            }
            VStack(alignment: .leading, spacing: 8) {
                SettingsGroup(title: "Permissions") {
                    PermissionsPanel(model: model)
                        .disabled(!model.canChangeSettings)
                }
                InfoDisclosure(label: "About these permissions", text: PermissionsPanel.details)
            }
            AboutSection()
        }
    }

    private func fact(_ title: String, _ text: String, details: String? = nil, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(title)
                    .font(AppType.rowTitle)
                    .frame(width: 92, alignment: .leading)
                VStack(alignment: .leading, spacing: 6) {
                    Text(text)
                        .font(AppType.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let details {
                        InfoDisclosure(label: "\(title) details", text: details)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            if !last { RowDivider() }
        }
    }
}
