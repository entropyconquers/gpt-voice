import ApplicationServices
import AVFoundation
import DictationCore
import Foundation

/// Command-line modes. Never prompts for permissions and never prints credential values.
enum CommandLineTool {
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "development"
    }

    /// Prints status JSON. Reads status only.
    static func diagnose() -> Int32 {
        FontRegistration.registerBundledFonts()
        var result: [String: Any] = [
            "appVersion": appVersion,
            "microphone": microphoneName(AVCaptureDevice.authorizationStatus(for: .audio)),
            "accessibility": AccessibilityPermission.check(),
            "inputMonitoring": InputMonitoringPermission.isGranted,
            "codexCLIAvailable": CodexAuthentication.cliAvailable,
            "bundledFonts": FontRegistration.fontAvailability
        ]
        do {
            let credentials = try CodexCredentials.load()
            result["authAvailable"] = true
            result["needsRefresh"] = credentials.needsRefresh
        } catch {
            result["authAvailable"] = false
            result["needsRefresh"] = NSNull()
            result["authError"] = error.localizedDescription
        }
        return printJSON(result, to: .standardOutput) ? 0 : 1
    }

    /// Prints only the transcript to stdout. Failures go to stderr.
    static func transcribe(path: String) async -> Int32 {
        let url = URL(fileURLWithPath: path)
        do {
            let text = try await TranscriptionClient().transcribe(file: url)
            FileHandle.standardOutput.write(Data((text + "\n").utf8))
            return 0
        } catch {
            FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
            return 1
        }
    }

    /// Renews the shared sign-in through Codex CLI. Prints success or failure metadata only.
    static func refreshAuthCheck() async -> Int32 {
        do {
            let credentials = try await CodexAuthentication.refresh()
            _ = printJSON(["ok": true, "needsRefresh": credentials.needsRefresh], to: .standardOutput)
            return 0
        } catch {
            _ = printJSON(["ok": false, "error": error.localizedDescription], to: .standardError)
            return 1
        }
    }

    static func usageError(_ message: String) -> Int32 {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        return 2
    }

    private static func microphoneName(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }

    private static func printJSON(_ object: [String: Any], to handle: FileHandle) -> Bool {
        guard var data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return false
        }
        data.append(0x0a)
        handle.write(data)
        return true
    }
}
