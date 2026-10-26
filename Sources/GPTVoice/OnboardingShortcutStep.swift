import SwiftUI

struct OnboardingShortcutStep: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingHeader(title: "Choose a shortcut",
                             summary: model.preferences.hotkey.isModifierHold
                                 ? "Hold it to record. Let go to paste the transcript."
                                 : "Press it once to start dictation. Press it again to stop.")
            ShortcutPanel(model: model)
        }
    }
}
