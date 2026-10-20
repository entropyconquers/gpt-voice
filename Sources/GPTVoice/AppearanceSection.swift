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
            SettingsGroup(title: "Recording bar") {
                AppearancePreview()
            }
        }
    }
}
