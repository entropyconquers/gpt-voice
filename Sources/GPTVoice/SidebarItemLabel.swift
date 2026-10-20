import AppKit
import SwiftUI

/// Rendering for `SidebarButtonStyle`.
struct SidebarItemLabel: View {
    let configuration: ButtonStyle.Configuration
    let isSelected: Bool
    let symbol: String

    @State private var hovering = false
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(width: 16)
            configuration.label
                .font(isSelected ? AppType.rowTitle : AppType.body)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? AppPalette.well : (hovering ? AppPalette.well.opacity(0.5) : .clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                .opacity(isFocused ? 1 : 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(configuration.isPressed ? 0.75 : 1)
        .animation(AppMotion.control(reduceMotion), value: hovering)
        .onHover { hovering = $0 }
    }
}
