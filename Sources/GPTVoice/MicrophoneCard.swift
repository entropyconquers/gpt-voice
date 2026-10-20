import SwiftUI

/// Microphone row. Purpose in one short line. Recovery text only when blocked or restricted.
struct MicrophoneCard: View {
    @ObservedObject var model: AppModel
    /// True when the grant action is the view's single main action.
    var prominent = true

    var body: some View {
        switch model.microphone {
        case .granted:
            StatusRow(tone: .good, symbol: "checkmark.circle.fill", title: "Microphone",
                      value: "Allowed") { EmptyView() }
        case .notRequested:
            StatusRow(tone: .attention, symbol: "exclamationmark.circle.fill", title: "Microphone",
                      detail: "Required to hear you.") {
                Button("Allow") { model.requestMicrophone() }
                    .buttonStyle(AppButtonStyle(kind: prominent ? .primary : .secondary, small: true))
                    .accessibilityLabel("Allow microphone")
                settingsButton
            }
        case .denied:
            StatusRow(tone: .problem, symbol: "mic.slash.fill", title: "Microphone blocked",
                      detail: "Turn on GPT Voice in Privacy & Security > Microphone.") {
                settingsButton
                recheck
            }
        case .restricted:
            StatusRow(tone: .problem, symbol: "lock.fill", title: "Microphone restricted",
                      detail: "A device policy or Screen Time blocks it. Ask the person who manages this Mac.") {
                settingsButton
                recheck
            }
        }
    }

    private var settingsButton: some View {
        Button("Open Settings") { model.openMicrophoneSettings() }
            .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
            .accessibilityLabel("Open microphone settings")
    }

    private var recheck: some View {
        QuietIconButton(symbol: "arrow.clockwise", label: "Check microphone again") { model.refreshStatus() }
    }
}
