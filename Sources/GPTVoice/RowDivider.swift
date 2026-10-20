import SwiftUI

/// The hairline between rows inside a SettingsGroup.
struct RowDivider: View {
    var body: some View {
        Rectangle().fill(AppPalette.hairline).frame(height: 1).accessibilityHidden(true)
    }
}
