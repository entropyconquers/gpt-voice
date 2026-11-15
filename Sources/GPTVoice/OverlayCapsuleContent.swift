import SwiftUI

/// Shared content for the live, resizing shell and the static preview.
struct OverlayCapsuleContent: View {
    let state: DictationOverlayState
    let actions: DictationOverlayActions
    var contents: PillContents = .standard

    @ViewBuilder var body: some View {
        switch state {
        case .recording(let elapsed, let level):
            if contents.recordingDot {
                Circle().fill(AppPalette.recording).frame(width: 7, height: 7)
                    .accessibilityLabel("Recording")
            }
            if contents.showsWaveform {
                LevelMeterView(level: level).frame(width: 36, height: 18)
                    .accessibilityLabel("Recording level")
            }
            if contents.timer {
                Text(DictationOverlayState.format(elapsed))
                    .font(AppType.timer)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Elapsed \(DictationOverlayState.format(elapsed))")
            }
            if contents.cancelButton {
                OverlayIconButton(symbol: "xmark", label: "Cancel dictation", action: actions.cancel)
            }
            if contents.stopButton {
                OverlayIconButton(symbol: "stop.fill", label: "Stop and transcribe", prominent: true, action: actions.stop)
            }
        case .working(let label, let cancellable):
            // Secondary-label ring: visible on light and dark surfaces, unlike the small system spinner.
            ActivityIndicator(size: 13, accessibilityText: contents.statusText ? nil : label)
                .frame(width: 16, height: 16)
            if contents.statusText {
                Text(label)
                    .font(AppType.control)
                    .lineLimit(1)
                    .frame(minWidth: 96, alignment: .leading)
            }
            if cancellable && contents.cancelButton {
                OverlayIconButton(symbol: "xmark", label: "Cancel dictation", action: actions.cancel)
            }
        case .success(let label):
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppPalette.success)
                .accessibilityHidden(contents.statusText)
                .accessibilityLabel(label)
            if contents.statusText {
                Text(label)
                    .font(AppType.control)
                    .lineLimit(1)
                    .padding(.trailing, 8)
            }
        case .message(let label, let kind):
            Image(systemName: kind == .noSpeech ? "waveform.slash" :
                    kind == .warning ? "exclamationmark.circle" : "doc.on.clipboard")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(label)
                .font(AppType.control)
                .lineLimit(1)
                .padding(.trailing, 8)
        case .hidden, .notice:
            EmptyView()
        }
    }
}
