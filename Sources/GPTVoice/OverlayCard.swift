import SwiftUI

/// The first manual-paste explanation. Later results use a compact message.
struct OverlayCard: View {
    let notice: DictationOverlayNotice
    let actions: DictationOverlayActions

    var body: some View {
        OverlayHelpContent(notice: notice, dismiss: actions.dismiss)
            .modifier(OverlaySurface(shape: RoundedRectangle(cornerRadius: 14, style: .continuous)))
    }
}
