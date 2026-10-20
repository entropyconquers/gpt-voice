import SwiftUI

/// Accessibility row for automatic paste. Optional, so it never uses a warning tone.
struct AccessibilityCard: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences
    var offersManualPaste = false

    init(model: AppModel, offersManualPaste: Bool = false) {
        self.model = model
        self.preferences = model.preferences
        self.offersManualPaste = offersManualPaste
    }

    var body: some View {
        if model.accessibilityTrusted {
            StatusRow(tone: .good, symbol: "checkmark.circle.fill", title: "Accessibility",
                      detail: preferences.automaticPaste ? "" : "Automatic paste is off.", value: "Allowed") {
                if !preferences.automaticPaste {
                    Button("Turn on paste") { model.setAutomaticPaste(true) }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                }
            }
        } else if !preferences.automaticPaste {
            StatusRow(tone: .neutral, symbol: "doc.on.clipboard", title: "Manual paste",
                      detail: "Text is copied. You press ⌘V.") {
                Button("Use automatic paste") { model.setAutomaticPaste(true) }
                    .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                StatusRow(tone: .neutral, symbol: "circle.dashed", title: "Accessibility",
                          detail: "Optional. Lets the app paste for you.") {
                    Button("Allow") { model.requestAccessibility() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                        .accessibilityLabel("Allow Accessibility")
                    Button("Open Settings") { model.openAccessibilitySettings() }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                        .accessibilityLabel("Open Accessibility settings")
                    QuietIconButton(symbol: "arrow.clockwise", label: "Check Accessibility again") {
                        model.refreshStatus()
                    }
                }
                if offersManualPaste {
                    Button("Skip and use manual paste") { model.setAutomaticPaste(false) }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                        .padding(.leading, 16)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}
