import SwiftUI

struct OnboardingPermissionsStep: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingHeader(title: "Allow access",
                             summary: "The microphone is required. Accessibility is optional.")
            VStack(alignment: .leading, spacing: 8) {
                SettingsGroup {
                    PermissionsPanel(model: model, offersManualPaste: true, prominent: true)
                }
                InfoDisclosure(label: "Why these permissions?", text: PermissionsPanel.details)
            }
        }
    }
}
