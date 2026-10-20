import SwiftUI

/// Inline problem text with a symbol. It stays visible until the state changes.
struct ErrorMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppPalette.problem)
            Text(text).font(AppType.detail).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Problem: \(text)")
    }
}
