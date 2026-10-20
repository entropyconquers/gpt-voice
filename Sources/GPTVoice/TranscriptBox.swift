import SwiftUI

/// The one practice transcript area, shown only after a real result. Selectable, and scrolls when long.
struct TranscriptBox: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(AppType.body)
                .lineSpacing(3)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(16)
        }
        .frame(minHeight: 64, maxHeight: 140)
        .fixedSize(horizontal: false, vertical: true)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppPalette.surface))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppPalette.hairline))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transcript: \(text)")
    }
}
