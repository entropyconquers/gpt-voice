import AppKit
import ApplicationServices
import Combine

/// Status-only diagnostics for the explicit file-to-paste verification mode.
/// It never logs audio, transcripts, clipboard contents, credentials, or window titles.
@MainActor
final class VerificationTrace {
    private var observer: AnyCancellable?

    init(model: AppModel) {
        Self.write([
            "event": "start",
            "targetBundleID": NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown",
            "accessibility": AXIsProcessTrusted()
        ])
        observer = model.$phase.sink { phase in
            var fields: [String: Any] = ["event": "phase", "status": phase.statusText]
            switch phase {
            case .finished(let outcome): fields["delivery"] = outcome.message
            case .failed(let failure): fields["error"] = failure.message
            default: break
            }
            Self.write(fields)
        }
    }

    private static func write(_ fields: [String: Any]) {
        guard var data = try? JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys]) else { return }
        data.append(0x0A)
        FileHandle.standardError.write(data)
    }
}
