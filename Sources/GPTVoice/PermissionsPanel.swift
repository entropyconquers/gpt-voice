import SwiftUI

/// Microphone and Accessibility rows with real grant and recovery actions. Place inside a SettingsGroup.
struct PermissionsPanel: View {
    @ObservedObject var model: AppModel
    var offersManualPaste = false
    /// True when the microphone grant is the view's single main action.
    var prominent = false

    init(model: AppModel, offersManualPaste: Bool = false, prominent: Bool = false) {
        self.model = model
        self.offersManualPaste = offersManualPaste
        self.prominent = prominent
    }

    var body: some View {
        VStack(spacing: 0) {
            MicrophoneCard(model: model, prominent: prominent)
            RowDivider()
            AccessibilityCard(model: model, offersManualPaste: offersManualPaste)
        }
    }

    /// Secondary detail shown behind a disclosure wherever permissions appear.
    static let details = "The microphone records only between your two shortcut presses. Accessibility lets the app press ⌘V in the app you were using. It never presses Return. macOS asks you to confirm each permission. This app cannot turn them on for you."
}
