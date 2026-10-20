import SwiftUI

/// A 24 pt round icon button for the compact overlay. Always has an accessible name.
struct OverlayIconButton: View {
    let symbol: String
    let label: String
    var prominent = false
    let action: () -> Void
    @Environment(\.appAccentFill) private var accent
    @Environment(\.appAccentOnFill) private var onAccent

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(prominent ? onAccent : Color.primary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(prominent ? accent : Color.primary.opacity(0.1)))
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .help(label)
        .accessibilityLabel(label)
    }
}
