import AppKit
import SwiftUI

/// Accent swatches. Each is a focusable button with a name, and a check plus ring when selected.
struct AccentSwatchPicker: View {
    @Binding var selection: AccentChoice
    @FocusState private var focused: AccentChoice?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AccentChoice.allCases) { choice in
                Button {
                    selection = choice
                } label: {
                    swatch(choice)
                }
                .buttonStyle(PressScaleButtonStyle())
                .focused($focused, equals: choice)
                .modifier(KeyboardFocusRing(isFocused: focused == choice, shape: Circle()))
                .help(choice.title)
                .accessibilityLabel("\(choice.title) accent")
                .accessibilityValue(choice == selection ? "Selected" : "")
                .accessibilityAddTraits(choice == selection ? .isSelected : [])
            }
        }
    }

    private func swatch(_ choice: AccentChoice) -> some View {
        let selected = choice == selection
        return ZStack {
            Circle()
                .strokeBorder(selected ? Color.primary.opacity(0.45) : Color.clear, lineWidth: 1.5)
                .frame(width: 26, height: 26)
            Circle()
                .fill(choice.color)
                .frame(width: 18, height: 18)
                .overlay(Circle().strokeBorder(AppPalette.hairline))
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(choice.onFill)
            }
        }
        .frame(width: 26, height: 26)
        .contentShape(Circle())
    }
}
