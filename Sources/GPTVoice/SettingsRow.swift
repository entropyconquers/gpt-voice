import SwiftUI

/// Label and detail on the leading side, control on the trailing side, with a divider below.
/// Stacks the control under the label when the row is too narrow.
struct SettingsRow<Control: View>: View {
    let title: String
    var detail: String?
    var showsDivider = true
    @ViewBuilder var control: () -> Control

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    labels
                    Spacer(minLength: 12)
                    control()
                }
                VStack(alignment: .leading, spacing: 10) {
                    labels
                    control()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            if showsDivider {
                Rectangle().fill(AppPalette.hairline).frame(height: 1).accessibilityHidden(true)
            }
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppType.rowTitle)
            if let detail {
                Text(detail)
                    .font(AppType.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
