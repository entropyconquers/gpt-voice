import SwiftUI

/// Automatic paste, sound cues, and launch at login. Short labels. A detail only when it changes a decision.
struct BehaviorSection: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences

    init(model: AppModel) {
        self.model = model
        self.preferences = model.preferences
    }

    private var showsLoginIssue: Bool {
        model.launchAtLoginError != nil || model.launchAtLogin == .requiresApproval
    }

    var body: some View {
        SettingsGroup {
            SettingsRow(title: "Paste automatically",
                        detail: model.accessibilityTrusted ? nil : "Needs Accessibility. Until then, text is copied.") {
                AppToggle(label: "Paste automatically",
                          isOn: Binding(get: { preferences.automaticPaste }, set: { model.setAutomaticPaste($0) }))
                    .disabled(!model.canChangeSettings)
            }
            SettingsRow(title: "Sound cues") {
                AppToggle(label: "Sound cues",
                          isOn: Binding(get: { preferences.soundCues }, set: { model.setSoundCues($0) }))
                    .disabled(!model.canChangeSettings)
            }
            SettingsRow(title: "Open at login", showsDivider: showsLoginIssue) {
                AppToggle(label: "Open at login",
                          isOn: Binding(get: { model.launchAtLogin.isOn }, set: { model.setLaunchAtLogin($0) }))
                    .disabled(!model.canChangeSettings)
            }
            if showsLoginIssue {
                StatusRow(tone: model.launchAtLoginError == nil ? .attention : .problem,
                          symbol: "exclamationmark.circle.fill",
                          title: model.launchAtLoginError == nil ? "Needs approval in Login Items" : "Login item problem",
                          detail: model.launchAtLoginError ?? "") {
                    Button("Open Login Items") { model.openLoginItemsSettings() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, showsArrow: true, small: true))
                }
            }
        }
    }
}
