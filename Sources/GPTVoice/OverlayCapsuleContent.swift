import SwiftUI

/// Shared content for the live, resizing shell and the static preview.
struct OverlayCapsuleContent: View {
    let state: DictationOverlayState
    let actions: DictationOverlayActions

    @ViewBuilder var body: some View {
        switch state {
        case .recording(let elapsed, let level):
            Circle().fill(AppPalette.recording).frame(width: 7, height: 7)
                .accessibilityLabel("Recording")
            LevelMeterView(level: level).frame(width: 36, height: 18)
            Text(DictationOverlayState.format(elapsed))
                .font(AppType.timer)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityLabel("Elapsed \(DictationOverlayState.format(elapsed))")
            OverlayIconButton(symbol: "xmark", label: "Cancel dictation", action: actions.cancel)
            OverlayIconButton(symbol: "stop.fill", label: "Stop and transcribe", prominent: true, action: actions.stop)
        case .working(let label, let cancellable):
            // Secondary-label ring: visible on light and dark surfaces, unlike the small system spinner.
            ActivityIndicator(size: 13)
                .frame(width: 16, height: 16)
            Text(label)
                .font(AppType.control)
                .lineLimit(1)
                .frame(minWidth: 96, alignment: .leading)
            if cancellable {
                OverlayIconButton(symbol: "xmark", label: "Cancel dictation", action: actions.cancel)
            } else {
                Color.clear.frame(width: 6, height: 24)
            }
        case .success(let label):
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppPalette.success)
                .accessibilityHidden(true)
            Text(label)
                .font(AppType.control)
                .lineLimit(1)
                .padding(.trailing, 8)
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
