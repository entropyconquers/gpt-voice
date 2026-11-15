import SwiftUI

/// Keeps one surface while the window resizes and the content cross-fades.
struct DictationPanelView: View {
    @ObservedObject var presentation: OverlayPresentation
    @ObservedObject var preferences: AppPreferences
    let actions: DictationOverlayActions
    let timing: OverlayTiming
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { _ in
            ZStack {
                content
                    .id(presentation.state.transitionID)
                    .transition(OverlayContentTransition.transition(reduceMotion: reduceMotion))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: reduceMotion ? timing.reducedFade : timing.resize),
                       value: presentation.state.transitionID)
            .blur(radius: presentation.exiting && !reduceMotion ? 2.5 : 0)
            .animation(.easeOut(duration: reduceMotion ? timing.reducedFade : timing.exit),
                       value: presentation.exiting)
            .modifier(OverlaySurface(shape: RoundedRectangle(cornerRadius: presentation.state.isHelp ? 14 : 20,
                                                              style: .continuous)))
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dictation status")
    }

    @ViewBuilder private var content: some View {
        if case .notice(let notice) = presentation.state {
            OverlayHelpContent(notice: notice, dismiss: actions.dismiss)
        } else {
            HStack(spacing: 10) {
                OverlayCapsuleContent(state: presentation.state, actions: actions, contents: preferences.pillContents)
            }
            .padding(.horizontal, 8)
            .frame(minWidth: 40, minHeight: 40, maxHeight: 40)
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
