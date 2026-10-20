import Foundation

public enum DictationError: LocalizedError {
    case signInRequired
    case invalidCredentials
    case refreshUnavailable
    case refreshFailed
    case signInFailed
    case invalidAudio
    case audioTooLarge
    case service(Int)
    case invalidResponse
    case emptyTranscript

    public var errorDescription: String? {
        switch self {
        case .signInRequired: return "Sign in with ChatGPT in Codex CLI. Run: codex login"
        case .invalidCredentials: return "Codex sign-in data could not be read. Run: codex login"
        case .refreshUnavailable: return "Install Codex CLI to renew your ChatGPT sign-in."
        case .refreshFailed: return "Your ChatGPT sign-in could not be renewed. Run: codex login"
        case .signInFailed: return "ChatGPT sign-in did not finish. Select Sign in with ChatGPT to try again."
        case .invalidAudio: return "Choose a WAV, M4A, MP3, MP4, WebM, Ogg, or FLAC audio file."
        case .audioTooLarge: return "This app accepts recordings smaller than 20 MB."
        case .service(401): return "Your ChatGPT sign-in expired. Run: codex login"
        case .service(403): return "ChatGPT denied this dictation request for your account."
        case .service(429): return "ChatGPT reached a request limit. Try again later."
        case .service(let code): return "ChatGPT could not transcribe this recording (HTTP \(code))."
        case .invalidResponse: return "ChatGPT returned an unreadable transcript."
        case .emptyTranscript: return "No speech was found. Try another recording."
        }
    }
}
