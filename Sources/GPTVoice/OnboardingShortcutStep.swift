import SwiftUI

struct OnboardingShortcutStep: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingHeader(title: "Choose a shortcut",
                             summary: "Press it once to start dictation. Press it again to stop.")
            ShortcutPanel(model: model)
        }
    }
}
