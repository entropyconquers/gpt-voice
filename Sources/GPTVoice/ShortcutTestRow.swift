import SwiftUI

/// Checks that the real global shortcut reaches this app. The model's Carbon handler reports receipt.
/// Nothing here listens for keys, records, transcribes, pastes, or touches the clipboard.
struct ShortcutTestRow: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences

    init(model: AppModel) {
        self.model = model
        self.preferences = model.preferences
    }

    var body: some View {
        Group {
            switch model.shortcutTestStatus {
            case .idle:
                SettingsRow(title: "Test shortcut", showsDivider: false) {
                    Button("Test") { model.beginShortcutTest() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                        .disabled(!model.canChangeSettings)
                        .accessibilityLabel("Test shortcut")
                }
            case .listening:
                StatusRow(tone: .working, symbol: "", title: "Press \(preferences.hotkey.displayLabel)",
                          detail: "Microphone off") {
                    Button("Cancel") { model.endShortcutTest() }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                }
            case .received:
                StatusRow(tone: .good, symbol: "checkmark.circle.fill", title: "Shortcut received",
                          detail: "Nothing was recorded.") {
                    Button("Done") { model.endShortcutTest() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                }
            case .unavailable(let reason):
                StatusRow(tone: .problem, symbol: "exclamationmark.triangle.fill",
                          title: "Cannot test the shortcut", detail: reason) {
                    if model.hotkeyBlockedBySystem {
                        Button("Keyboard settings") { model.openKeyboardShortcutsSettings() }
                            .buttonStyle(AppButtonStyle(kind: .secondary, showsArrow: true, small: true))
                    }
                    Button("Done") { model.endShortcutTest() }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
