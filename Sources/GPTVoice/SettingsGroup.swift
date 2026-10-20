import SwiftUI

/// One section: an optional heading, then rows on a single flat surface (radius 12, one hairline).
/// Rows inside use dividers. Never nest a group inside another group.
struct SettingsGroup<Content: View>: View {
    var title: String?
    var footnote: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(AppType.heading)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: 0) { content() }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppPalette.surface))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppPalette.hairline))
            if let footnote {
                Text(footnote)
                    .font(AppType.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
