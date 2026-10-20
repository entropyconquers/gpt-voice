import SwiftUI

/// One readiness line: symbol, name in a fixed label column, value in an aligned column, and a fix action.
/// When the row is too narrow, the value moves under the name instead of breaking the column.
struct ReadinessRow: View {
    enum Status {
        case ready
        case missing
        case optional
    }

    let title: String
    let detail: String
    let status: Status
    var fixTitle = "Fix"
    var showsDivider = true
    var fix: (() -> Void)?

    /// Fits the longest label ("Automatic paste") in Regola Medium 14 with room to spare.
    private static let labelColumn: CGFloat = 132

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 16)
                    .accessibilityHidden(true)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(title).font(AppType.rowTitle)
                            .frame(width: Self.labelColumn, alignment: .leading)
                        value
                        Spacer(minLength: 8)
                        fixButton
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title).font(AppType.rowTitle)
                            value
                        }
                        Spacer(minLength: 8)
                        fixButton
                    }
                }
            }
            .padding(.vertical, 12)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(title), \(statusWord), \(detail)")
            if showsDivider { RowDivider() }
        }
    }

    private var value: some View {
        Text(detail)
            .font(AppType.detail)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var fixButton: some View {
        if let fix, status != .ready {
            Button(fixTitle, action: fix)
                .buttonStyle(AppButtonStyle(kind: status == .missing ? .secondary : .quiet, small: true))
                .fixedSize()
                .accessibilityLabel("\(fixTitle): \(title)")
        }
    }

    private var statusWord: String {
        switch status {
        case .ready: return "ready"
        case .missing: return "missing"
        case .optional: return "optional"
        }
    }

    private var symbol: String {
        switch status {
        case .ready: return "checkmark.circle.fill"
        case .missing: return "exclamationmark.circle.fill"
        case .optional: return "circle.dashed"
        }
    }

    private var color: Color {
        switch status {
        case .ready: return AppPalette.success
        case .missing: return AppPalette.warning
        case .optional: return .secondary
        }
    }
}
