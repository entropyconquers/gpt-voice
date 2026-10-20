import Foundation

enum AudioCaptureError: LocalizedError, Equatable {
    case microphoneDenied
    case alreadyRecording
    case notRecording
    case cancelled
    case startFailed
    case deviceFailed

    var errorDescription: String? {
        switch self {
        case .microphoneDenied: return "Microphone access is off. Turn it on in System Settings."
        case .alreadyRecording: return "A recording is already active."
        case .notRecording: return "No recording is active."
        case .cancelled: return "Recording was cancelled."
        case .startFailed: return "Recording could not start. Check your microphone."
        case .deviceFailed: return "The microphone stopped working. Your audio up to this point is kept."
        }
    }
}
