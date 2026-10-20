import AppKit
import SwiftUI

/// Compact switch (36×20). A native button underneath, so Space and Return toggle it with keyboard focus.
/// VoiceOver reads the label, "On" or "Off", and the hint.
struct AppToggle: View {
    let label: String
    var hint: String = ""
    @Binding var isOn: Bool

    @FocusState private var focused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appAccentFill) private var accentFill

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? accentFill : AppPalette.well)
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                    .padding(2)
            }
            .frame(width: 36, height: 20)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .focused($focused)
        .overlay(
            Capsule()
                .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                .padding(-3)
                .opacity(focused ? 1 : 0)
        )
        .opacity(isEnabled ? 1 : 0.4)
        .animation(AppMotion.control(reduceMotion), value: isOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isOn.toggle() }
    }
}
