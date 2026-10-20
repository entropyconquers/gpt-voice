import SwiftUI

/// The real recording bar views in two sample states. No microphone use.
struct AppearancePreview: View {
    private static let recording = DictationOverlayState.recording(elapsed: 12, level: 0.5)
    private static let working = DictationOverlayState.working(label: "Transcribing", cancellable: true)

    var body: some View {
        HStack(spacing: 12) {
            DictationOverlayView(state: Self.recording, actions: .preview)
            DictationOverlayView(state: Self.working, actions: .preview)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sample recording bar")
    }
}
