import SwiftUI

/// Real practice dictation in one action area. Starts only when the user selects Start.
/// The transcript area appears only after a real result. The result is never pasted or copied.
struct PracticeConsole: View {
    @ObservedObject var model: AppModel
    let goTo: (OnboardingStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsGroup {
                if let blocker {
                    blocker
                } else {
                    actionArea
                }
            }
            if blocker == nil, let text = model.practiceTranscript {
                TranscriptBox(text: text)
            }
        }
    }

    /// The phase only while this window owns a practice session. Otherwise idle.
    private var sessionPhase: DictationPhase { model.isPracticeSession ? model.phase : .idle }

    private var blocker: AnyView? {
        if model.isPracticeSession { return nil }
        if model.phase.isBusy {
            return AnyView(StatusRow(tone: .working, symbol: "", title: "Another dictation is running") {
                Button("Cancel it") { model.cancel() }
                    .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                    .disabled(!model.phase.canCancel)
            })
        }
        if !model.connection.isUsable {
            return AnyView(StatusRow(tone: .attention, symbol: "exclamationmark.circle.fill",
                                     title: "Sign in to ChatGPT first") {
                Button("Go to Connect") { goTo(.welcome) }
                    .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
            })
        }
        if model.microphone != .granted {
            return AnyView(StatusRow(tone: .attention, symbol: "exclamationmark.circle.fill",
                                     title: "Allow the microphone first") {
                Button("Go to Access") { goTo(.permissions) }
                    .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
            })
        }
        return nil
    }

    @ViewBuilder private var actionArea: some View {
        switch sessionPhase {
        case .preparing:
            StatusRow(tone: .working, symbol: "", title: "Starting the microphone") { cancelButton }
        case .recording:
            HStack(spacing: 10) {
                Circle().fill(AppPalette.recording).frame(width: 7, height: 7).accessibilityHidden(true)
                Text("Listening").font(AppType.rowTitle)
                Text(DictationOverlayState.format(model.elapsed))
                    .font(AppType.timer)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Elapsed \(DictationOverlayState.format(model.elapsed))")
                LevelMeterView(level: model.level).frame(width: 44, height: 16)
                Spacer(minLength: 8)
                cancelButton
                Button("Stop") { model.stopDictation() }
                    .buttonStyle(AppButtonStyle(kind: .primary, small: true))
            }
            .padding(.vertical, 12)
        case .transcribing:
            StatusRow(tone: .working, symbol: "", title: "Transcribing") { cancelButton }
        case .failed(let failure):
            StatusRow(tone: .problem, symbol: "exclamationmark.triangle.fill",
                      title: "Practice did not finish", detail: failure.message) {
                if model.canRetry {
                    Button("Retry") { model.retry() }
                        .buttonStyle(AppButtonStyle(kind: .primary, small: true))
                }
                switch failure.recovery {
                case .microphoneSettings:
                    Button("Microphone settings") { model.openMicrophoneSettings() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                case .signInThenRetry:
                    Button("Go to Connect") { goTo(.welcome) }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                case .retry, .none:
                    EmptyView()
                }
                Button("Start over") { model.startPracticeDictation() }
                    .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
            }
        default:
            SettingsRow(title: model.practiceTranscript == nil ? "Ready when you are" : "Try another sentence",
                        detail: "Your clipboard does not change.", showsDivider: false) {
                Button(model.practiceTranscript == nil ? "Start" : "Try again") { model.startPracticeDictation() }
                    .buttonStyle(AppButtonStyle(kind: model.practiceTranscript == nil ? .primary : .secondary,
                                                small: true))
                    .disabled(!model.canStart)
                    .accessibilityLabel(model.practiceTranscript == nil ? "Start practice" : "Try again")
            }
        }
    }

    /// Cancel keeps the practice context, so a later shortcut press still practices here.
    private var cancelButton: some View {
        Button("Cancel") { model.cancel() }
            .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
    }
}
