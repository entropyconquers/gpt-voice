import SwiftUI

/// One status line inside a section: tone symbol, title, optional detail or trailing value, and trailing actions.
/// The symbol aligns with the title's first baseline. Actions sit at the trailing edge, and when the row is
/// too narrow they move under the text, aligned to the title. Includes its own vertical row inset.
struct StatusRow<Actions: View>: View {
    let tone: StatusTone
    let symbol: String
    let title: String
    var detail: String = ""
    /// A short state word shown on the same line, trailing, for healthy rows ("Allowed").
    var value: String?
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            indicator
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    labels
                    Spacer(minLength: 8)
                    trailing
                }
                VStack(alignment: .leading, spacing: 10) {
                    labels
                    trailing
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var indicator: some View {
        Group {
            if tone == .working {
                ActivityIndicator(size: 11)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tone.color)
            }
        }
        .frame(width: 16)
        .accessibilityHidden(true)
    }

    private var trailing: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let value {
                // Included in the labels' accessible name, so hidden here to avoid reading it twice.
                Text(value).font(AppType.detail).foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            actions()
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppType.rowTitle)
            if !detail.isEmpty {
                Text(detail)
                    .font(AppType.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleName)
    }

    /// One explicit name: title, then detail and value when present ("Microphone, Allowed").
    private var accessibleName: String {
        [title, detail, value ?? ""].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}
