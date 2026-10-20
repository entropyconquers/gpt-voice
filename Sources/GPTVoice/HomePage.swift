import SwiftUI

/// Home: each state shown once with its action, then the current shortcut and one line of instruction.
struct HomePage: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences
    let goTo: (SettingsPage) -> Void

    init(model: AppModel, goTo: @escaping (SettingsPage) -> Void) {
        self.model = model
        self.preferences = model.preferences
        self.goTo = goTo
    }

    var body: some View {
        let ready = model.missingRequirements.isEmpty
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(footnote: ready
                ? "Press \(preferences.hotkey.displayLabel) in any app to start. Press it again to stop."
                : "Dictation works once the items marked here are fixed.") {
                ConnectionPanel(model: model, prominentSignIn: false)
                    .disabled(!model.canChangeSettings)
                RowDivider()
                MicrophoneCard(model: model, prominent: false)
                RowDivider()
                AccessibilityCard(model: model)
                RowDivider()
                SettingsRow(title: "Shortcut", showsDivider: false) {
                    HStack(spacing: 8) {
                        KeycapsView(spec: preferences.hotkey)
                        Button("Change") { goTo(.shortcuts) }
                            .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                    }
                }
            }

            InfoDisclosure(label: "How dictation works",
                           text: "Click where you want the text. Press your shortcut and speak. Press it again to finish. With automatic paste, the text goes where you clicked. Otherwise it is copied and you press ⌘V.")
        }
    }
}
