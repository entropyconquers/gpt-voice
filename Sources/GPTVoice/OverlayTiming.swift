import Foundation

struct OverlayTiming {
    var resize: TimeInterval = 0.24
    var entrance: TimeInterval = 0.16
    var exit: TimeInterval = 0.18
    var reducedFade: TimeInterval = 0.1
    var success: TimeInterval = 1.6
    var noSpeech: TimeInterval = 2
    var warning: TimeInterval = 3
    var pasteHint: TimeInterval = 3
    var help: TimeInterval = 7.5

    func hold(for state: DictationOverlayState) -> TimeInterval? {
        switch state {
        case .success: return success
        case .message(_, .noSpeech): return noSpeech
        case .message(_, .warning): return warning
        case .message(_, .info): return pasteHint
        case .notice: return help
        case .hidden, .recording, .working: return nil
        }
    }
}
