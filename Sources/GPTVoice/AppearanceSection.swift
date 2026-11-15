import SwiftUI

/// Theme, accent, and bar position, then the real recording bar preview. Changes apply at once and persist.
struct AppearanceSection: View {
    @ObservedObject var preferences: AppPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup {
                SettingsRow(title: "Theme") {
                    AppSegmented(label: "Theme", options: AppTheme.allCases, title: \.title,
                                 selection: $preferences.theme)
                }
                SettingsRow(title: "Accent") {
                    AccentSwatchPicker(selection: $preferences.accent)
                }
                SettingsRow(title: "Bar position", showsDivider: false) {
                    AppSegmented(label: "Recording bar position", options: OverlayPlacement.allCases,
                                 title: \.title, selection: $preferences.overlayPlacement)
                }
            }
            SettingsGroup(title: "Pill contents",
                          footnote: "A recording indicator and loading circle always remain visible. Errors and copy instructions still appear.") {
                SettingsRow(title: "Presets") {
                    HStack(spacing: 6) {
                        Button("Minimal") { preferences.pillContents = .minimal }
                            .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                        Button("Full") { preferences.pillContents = .standard }
                            .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                    }
                }
                pillOption("Waveform", keyPath: \.waveform)
                pillOption("Timer", keyPath: \.timer)
                pillOption("Recording dot", keyPath: \.recordingDot)
                pillOption("Cancel button", keyPath: \.cancelButton)
                pillOption("Stop button", keyPath: \.stopButton)
                pillOption("Status labels", keyPath: \.statusText, showsDivider: false)
            }
            SettingsGroup(title: "Recording bar") {
                AppearancePreview(preferences: preferences)
            }
        }
    }

    private func pillOption(_ title: String, keyPath: WritableKeyPath<PillContents, Bool>,
                            showsDivider: Bool = true) -> some View {
        SettingsRow(title: title, showsDivider: showsDivider) {
            AppToggle(label: title, isOn: Binding(get: { preferences.pillContents[keyPath: keyPath] },
                set: { value in
                    var contents = preferences.pillContents
                    contents[keyPath: keyPath] = value
                    if !contents.waveform && !contents.timer && !contents.recordingDot { contents.waveform = true }
                    preferences.pillContents = contents
                }))
        }
    }
}
