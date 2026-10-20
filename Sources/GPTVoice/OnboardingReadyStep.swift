import SwiftUI

/// Compact truthful checks. No tutorial repeat. Missing items get one instruction and real Fix actions.
struct OnboardingReadyStep: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences
    let goTo: (OnboardingStep) -> Void

    init(model: AppModel, goTo: @escaping (OnboardingStep) -> Void) {
        self.model = model
        self.preferences = model.preferences
        self.goTo = goTo
    }

    var body: some View {
        let ready = model.missingRequirements.isEmpty
        VStack(alignment: .leading, spacing: 24) {
            OnboardingHeader(title: ready ? "Ready to dictate" : "Almost ready",
                             summary: ready
                                 ? "Press \(preferences.hotkey.displayLabel) in any app to start."
                                 : "Fix the items marked missing, or finish later in Settings.")
            SettingsGroup {
                ReadinessList(model: model) { fix in
                    switch fix {
                    case .connection: goTo(.welcome)
                    case .permissions: goTo(.permissions)
                    case .shortcut: goTo(.shortcut)
                    }
                }
            }
        }
    }
}
