import AppKit

/// Routes command-line modes, or runs the menu bar app.
@main
struct GPTVoiceEntryPoint {
    @MainActor
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        var launchOptions = LaunchOptions.normal

        switch arguments.first {
        case "--diagnose":
            exit(CommandLineTool.diagnose())
        case "--transcribe":
            guard let path = value(after: "--transcribe", in: arguments) else {
                exit(CommandLineTool.usageError("Usage: GPTVoice --transcribe FILE"))
            }
            runAsync { await CommandLineTool.transcribe(path: path) }
        case "--refresh-auth-check":
            runAsync { await CommandLineTool.refreshAuthCheck() }
        case "--show-onboarding":
            launchOptions = .showOnboarding
        case "--show-settings":
            launchOptions = .showSettings
        case "--transcribe-and-paste":
            guard let path = value(after: "--transcribe-and-paste", in: arguments) else {
                exit(CommandLineTool.usageError("Usage: GPTVoice --transcribe-and-paste FILE"))
            }
            launchOptions = .transcribeAndPaste(URL(fileURLWithPath: path))
        case "--practice-audio":
            guard let path = value(after: "--practice-audio", in: arguments) else {
                exit(CommandLineTool.usageError("Usage: GPTVoice --practice-audio FILE"))
            }
            launchOptions = .practiceAudio(URL(fileURLWithPath: path))
        case nil:
            break
        default:
            if arguments.first?.hasPrefix("-psn") != true {
                exit(CommandLineTool.usageError(
                    "Options: --diagnose, --transcribe FILE, --refresh-auth-check, --show-onboarding, "
                    + "--show-settings, --transcribe-and-paste FILE, --practice-audio FILE"))
            }
        }

        if SingleInstance.forwardToRunningInstance(launchOptions) {
            exit(0)
        }
        runApplication(launchOptions)
    }

    /// Runs the GUI app. Synchronous on the main actor.
    @MainActor
    private static func runApplication(_ options: LaunchOptions) {
        FontRegistration.registerBundledFonts()
        let app = NSApplication.shared
        let delegate = AppDelegate(options: options)
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
        // NSApplication holds the delegate weakly. Keep it alive for the whole run.
        withExtendedLifetime(delegate) {}
    }

    /// Runs one async CLI operation, then exits with its status.
    private static func runAsync(_ work: @escaping () async -> Int32) -> Never {
        Task { exit(await work()) }
        dispatchMain()
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
