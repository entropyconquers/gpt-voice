import SwiftUI

/// Page title, with a short subtitle only when the title needs one.
struct PageHeader: View {
    let title: String
    var intro: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppType.title)
                .tracking(AppType.titleTracking)
                .accessibilityAddTraits(.isHeader)
            if let intro {
                Text(intro)
                    .font(AppType.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
