import SwiftUI

/// The compact static preview. The live panel owns one continuously resizing surface.
struct OverlayCapsule: View {
    let state: DictationOverlayState
    let actions: DictationOverlayActions

    var body: some View {
        HStack(spacing: 10) {
            OverlayCapsuleContent(state: state, actions: actions)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .frame(height: 40)
        .fixedSize(horizontal: true, vertical: false)
        .modifier(OverlaySurface(shape: Capsule()))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dictation status")
    }
}
