import AppKit
import SwiftUI

/// A quiet, labelled disclosure for secondary detail. The label always names what it reveals.
/// A native button underneath, so it is keyboard focusable and VoiceOver reads "expanded" or "collapsed".
struct InfoDisclosure: View {
    let label: String
    let text: String

    @State private var expanded = false
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                    Text(label).font(AppType.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focused($focused)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                    .padding(-3)
                    .opacity(focused ? 1 : 0)
            )
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")

            if expanded {
                Text(text)
                    .font(AppType.detail)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 520, alignment: .leading)
                    .padding(.leading, 14)
                    .transition(.opacity)
            }
        }
        .animation(AppMotion.control(reduceMotion), value: expanded)
    }
}
