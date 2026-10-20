import SwiftUI

/// Shows a shortcut as flat keycaps, for example ⌘ Space. Regola Medium.
struct KeycapsView: View {
    let spec: HotkeySpec
    var large = false

    var body: some View {
        HStack(spacing: large ? 6 : 4) {
            ForEach(Array(spec.keycaps.enumerated()), id: \.offset) { _, cap in
                Text(cap)
                    .font(large ? AppType.keycapLarge : AppType.keycap)
                    .padding(.horizontal, large ? 12 : 7)
                    .frame(minWidth: large ? 44 : 26, minHeight: large ? 44 : 24)
                    .background(
                        RoundedRectangle(cornerRadius: large ? 10 : 6, style: .continuous)
                            .fill(AppPalette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: large ? 10 : 6, style: .continuous)
                            .strokeBorder(AppPalette.hairline)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spec.accessibilityLabel)
    }
}
