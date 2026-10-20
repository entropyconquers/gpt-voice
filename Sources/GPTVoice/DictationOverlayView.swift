import SwiftUI

/// Renders one overlay state. Shared by the live panel and the Appearance preview.
struct DictationOverlayView: View {
    let state: DictationOverlayState
    let actions: DictationOverlayActions

    var body: some View {
        switch state {
        case .notice(let notice):
            OverlayCard(notice: notice, actions: actions)
        case .hidden:
            EmptyView()
        default:
            OverlayCapsule(state: state, actions: actions)
        }
    }
}
