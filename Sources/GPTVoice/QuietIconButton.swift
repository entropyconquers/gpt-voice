import AppKit
import SwiftUI

/// Small borderless icon action for secondary, repeatable actions such as "check again".
/// Always has an accessible name and a tooltip.
struct QuietIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @State private var hovering = false
    @FocusState private var focused: Bool

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hovering ? AppPalette.well : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused($focused)
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                .padding(-2)
                .opacity(focused ? 1 : 0)
        )
        .onHover { hovering = $0 }
        .help(label)
        .accessibilityLabel(label)
    }
}
