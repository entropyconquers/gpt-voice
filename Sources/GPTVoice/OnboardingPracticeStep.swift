import SwiftUI

struct OnboardingPracticeStep: View {
    @ObservedObject var model: AppModel
    let goTo: (OnboardingStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingHeader(title: "Try it",
                             summary: "Say one sentence. The text stays in this window.")
            PracticeConsole(model: model, goTo: goTo)
        }
    }
}
