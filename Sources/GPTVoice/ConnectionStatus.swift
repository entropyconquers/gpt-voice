import DictationCore
import Foundation

/// The shared Codex CLI ChatGPT sign-in state. Never holds credentials.
enum ConnectionStatus: Equatable {
    case checking
    case connected
    /// The token expired. Codex CLI renews it on the next request.
    case expired
    case missing
    case unreadable
    case signingIn
    /// Codex CLI is renewing an expired sign-in. No browser is involved.
    case renewing

    /// Reads auth.json without prompting or renewing.
    static func current() -> ConnectionStatus {
        do {
            return try CodexCredentials.load().needsRefresh ? .expired : .connected
        } catch DictationError.signInRequired {
            return .missing
        } catch {
            return .unreadable
        }
    }

    var isUsable: Bool { self == .connected || self == .expired }

    var title: String {
        switch self {
        case .checking: return "Checking sign-in…"
        case .connected: return "Connected to ChatGPT"
        case .expired: return "Sign-in expired"
        case .missing: return "Not signed in"
        case .unreadable: return "Sign-in data can’t be read"
        case .signingIn: return "Waiting for browser…"
        case .renewing: return "Renewing sign-in…"
        }
    }

    var detail: String {
        switch self {
        case .checking: return ""
        case .connected: return "This app uses your Codex CLI sign-in."
        case .expired: return "Codex CLI renews it on your next dictation. Select Reconnect to renew it now."
        case .missing: return "Sign in with ChatGPT to start dictation."
        case .unreadable: return "Sign in with ChatGPT again to repair it."
        case .signingIn: return "Finish sign-in in your browser. Select Cancel to stop."
        case .renewing: return "Codex CLI is renewing your ChatGPT sign-in."
        }
    }
}
