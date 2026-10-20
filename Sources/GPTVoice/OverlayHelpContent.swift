import SwiftUI

struct OverlayHelpContent: View {
    let notice: DictationOverlayNotice
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(notice.title).font(AppType.rowTitle)
                Spacer(minLength: 8)
                OverlayIconButton(symbol: "xmark", label: "Dismiss paste help", action: dismiss)
            }
            Text(notice.message)
                .font(AppType.detail)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 320, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}
