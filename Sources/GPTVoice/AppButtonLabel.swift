import AppKit
import SwiftUI

/// Rendering for `AppButtonStyle`: default, hover, press, focus, loading, and disabled states.
struct AppButtonLabel: View {
    let configuration: ButtonStyle.Configuration
    let style: AppButtonStyle

    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appAccentFill) private var accentFill
    @Environment(\.appAccentOnFill) private var onAccent

    private var height: CGFloat { style.small ? 28 : 36 }
    private static let radius: CGFloat = 10

    var body: some View {
        HStack(spacing: 6) {
            if style.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
            }
            configuration.label
                .font(style.small ? AppType.controlSmall : AppType.control)
                .lineLimit(1)
            if style.showsArrow {
                Image(systemName: "arrow.right")
                    .font(.system(size: style.small ? 10 : 11, weight: .medium))
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, style.kind == .quiet ? 10 : (style.small ? 12 : 16))
        .frame(minHeight: height)
        .frame(maxWidth: style.fullWidth ? .infinity : nil)
        .background(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).fill(background))
        .overlay(RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
            .strokeBorder(style.kind == .secondary ? AppPalette.hairline : .clear))
        .overlay(
            RoundedRectangle(cornerRadius: Self.radius + 3, style: .continuous)
                .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                .padding(-3)
                .opacity(isFocused ? 1 : 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
        .opacity(isEnabled ? 1 : 0.4)
        .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
        .animation(AppMotion.control(reduceMotion), value: configuration.isPressed)
        .animation(AppMotion.control(reduceMotion), value: hovering)
        .onHover { hovering = $0 }
    }

    private var foreground: Color {
        switch style.kind {
        case .primary: return onAccent
        case .secondary, .quiet: return .primary
        case .destructive: return AppPalette.problem
        }
    }

    private var background: Color {
        let lift = hovering && isEnabled
        switch style.kind {
        case .primary: return accentFill.opacity(configuration.isPressed ? 0.8 : (lift ? 0.9 : 1))
        case .secondary: return lift ? AppPalette.well : AppPalette.surface
        case .quiet: return lift ? AppPalette.well : .clear
        case .destructive: return AppPalette.problemSoft.opacity(lift ? 1 : 0.75)
        }
    }
}
