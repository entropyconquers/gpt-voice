import SwiftUI

/// SwiftUI wrapper for the native shortcut recorder. Suspends the global shortcut while recording.
struct ShortcutRecorderField: NSViewRepresentable {
    @ObservedObject var model: AppModel
    let isEnabled: Bool

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        // Let the SwiftUI frame win over the view's intrinsic width, so the field never overhangs its row.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateNSView(_ view: ShortcutRecorderNSView, context: Context) {
        let model = model
        view.onBegin = { model.beginShortcutCapture() }
        view.onEnd = { model.endShortcutCapture() }
        view.onCapture = { model.setHotkey($0) }
        view.onProblem = { model.reportShortcutProblem($0) }
        view.currentLabel = model.hotkey.accessibilityLabel
        view.isEnabled = isEnabled
        view.accentColor = model.preferences.accent.nsColor
    }

    static func dismantleNSView(_ view: ShortcutRecorderNSView, coordinator: ()) {
        view.isEnabled = false
    }
}
