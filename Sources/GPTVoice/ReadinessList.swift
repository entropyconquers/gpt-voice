import SwiftUI

/// Real readiness checks as rows. Each row reflects actual state, never navigation. Place inside a SettingsGroup.
struct ReadinessList: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences
    let fix: (Fix) -> Void

    enum Fix {
        case connection
        case permissions
        case shortcut
    }

    init(model: AppModel, fix: @escaping (Fix) -> Void) {
        self.model = model
        self.preferences = model.preferences
        self.fix = fix
    }

    /// A short value that does not repeat the "ChatGPT" label.
    private var connectionValue: String {
        switch model.connection {
        case .checking: return "Checking"
        case .connected: return "Connected"
        case .expired: return "Sign-in expired"
        case .missing: return model.cliAvailable ? "Not signed in" : "Codex CLI not installed"
        case .unreadable: return "Sign-in unreadable"
        case .signingIn: return "Waiting for browser"
        case .renewing: return "Renewing"
        }
    }

    var body: some View {
        let shortcutWorks = !model.missingRequirements.contains("Choose a working shortcut")
        let automatic = preferences.automaticPaste && model.accessibilityTrusted
        VStack(spacing: 0) {
            ReadinessRow(title: "ChatGPT", detail: connectionValue,
                         status: model.connection.isUsable ? .ready : .missing) { fix(.connection) }
            ReadinessRow(title: "Microphone", detail: model.microphone.title,
                         status: model.microphone == .granted ? .ready : .missing) { fix(.permissions) }
            ReadinessRow(title: "Shortcut",
                         detail: shortcutWorks ? preferences.hotkey.accessibilityLabel : (model.hotkeyError ?? "Not registered"),
                         status: shortcutWorks ? .ready : .missing) { fix(.shortcut) }
            ReadinessRow(title: automatic ? "Automatic paste" : "Manual paste",
                         detail: automatic ? "On" : "Optional. Text is copied for ⌘V.",
                         status: automatic ? .ready : .optional, fixTitle: "Set up", showsDivider: false) {
                fix(.permissions)
            }
        }
    }
}
