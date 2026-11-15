import SwiftUI

/// The compact static preview. The live panel owns one continuously resizing surface.
struct OverlayCapsule: View {
    let state: DictationOverlayState
    let actions: DictationOverlayActions
    var contents: PillContents = .standard

    var body: some View {
        HStack(spacing: 10) {
            OverlayCapsuleContent(state: state, actions: actions, contents: contents)
        }
        .padding(.horizontal, 8)
        .frame(minWidth: 40, minHeight: 40, maxHeight: 40)
        .fixedSize(horizontal: true, vertical: false)
        .modifier(OverlaySurface(shape: Capsule()))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dictation status")
    }
}
