import SwiftUI

/// Shown while dictation is active and settings cannot change.
struct SettingsLockBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(AppPalette.recording).frame(width: 6, height: 6)
            Text("Dictation is active. Finish or cancel it to change settings.")
                .font(AppType.detail)
        }
        .accessibilityElement(children: .combine)
    }
}
