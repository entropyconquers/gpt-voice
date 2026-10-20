import Foundation

/// The single dictation operation state. Only one operation runs at a time.
enum DictationPhase: Equatable {
    case idle
    /// Waiting for microphone permission or a pending clipboard lease.
    case preparing
    case recording
    case transcribing
    case pasting
    case finished(PasteOutcome)
    case failed(DictationFailure)

    /// True while an operation owns the microphone, network, or clipboard.
    var isBusy: Bool {
        switch self {
        case .preparing, .recording, .transcribing, .pasting: return true
        case .idle, .finished, .failed: return false
        }
    }

    var canCancel: Bool {
        switch self {
        case .preparing, .recording, .transcribing: return true
        default: return false
        }
    }

    var statusText: String {
        switch self {
        case .idle: return "Ready"
        case .preparing: return "Getting ready…"
        case .recording: return "Listening…"
        case .transcribing: return "Transcribing…"
        case .pasting: return "Pasting…"
        case .finished(let outcome): return outcome.message
        case .failed(let failure): return failure.message
        }
    }
}
