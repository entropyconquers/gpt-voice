import SwiftUI

/// The ChatGPT row, through the shared Codex CLI sign-in. One line when healthy. Recovery text only when needed.
/// Place inside a SettingsGroup.
struct ConnectionPanel: View {
    @ObservedObject var model: AppModel
    /// True when the sign-in action is the view's single main action.
    var prominentSignIn = true

    var body: some View {
        VStack(spacing: 0) {
            row
            if let error = model.authError, model.connection != .signingIn, model.connection != .renewing {
                RowDivider()
                StatusRow(tone: .problem, symbol: "exclamationmark.triangle.fill",
                          title: "Sign-in did not finish", detail: error) {
                    Button("Try again") { model.signIn() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                }
            }
        }
    }

    private var cliMissing: Bool {
        !model.cliAvailable && (model.connection == .missing || model.connection == .unreadable)
    }

    private var mainKind: AppButtonStyle.Kind { prominentSignIn ? .primary : .secondary }

    @ViewBuilder private var row: some View {
        switch model.connection {
        case .checking:
            StatusRow(tone: .working, symbol: "", title: "Checking ChatGPT sign-in") { EmptyView() }
        case .connected:
            StatusRow(tone: .good, symbol: "checkmark.circle.fill", title: "Connected to ChatGPT") {
                QuietIconButton(symbol: "arrow.clockwise", label: "Check sign-in again") { model.refreshStatus() }
            }
        case .expired:
            StatusRow(tone: .attention, symbol: "clock.fill", title: "ChatGPT sign-in expired",
                      detail: "It renews on your next dictation.") {
                Button("Renew now") { model.reconnect() }
                    .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
            }
        case .renewing:
            StatusRow(tone: .working, symbol: "", title: "Renewing ChatGPT sign-in") {
                Button("Cancel") { model.cancelSignIn() }
                    .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
            }
        case .signingIn:
            StatusRow(tone: .working, symbol: "", title: "Waiting for your browser",
                      detail: "Finish signing in to ChatGPT, then come back.") {
                Button("Cancel") { model.cancelSignIn() }
                    .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
            }
        case .missing, .unreadable:
            if cliMissing {
                StatusRow(tone: .problem, symbol: "exclamationmark.circle.fill", title: "Codex CLI not installed",
                          detail: "Install Codex CLI to sign in, then check again.") {
                    Button("Install Codex") { model.openInstallCodex() }
                        .buttonStyle(AppButtonStyle(kind: mainKind, small: !prominentSignIn))
                    QuietIconButton(symbol: "arrow.clockwise", label: "Check again") { model.refreshStatus() }
                }
            } else if model.connection == .missing {
                StatusRow(tone: .attention, symbol: "exclamationmark.circle.fill", title: "Not signed in to ChatGPT") {
                    Button("Sign in with ChatGPT") { model.signIn() }
                        .buttonStyle(AppButtonStyle(kind: mainKind, small: !prominentSignIn))
                }
            } else {
                StatusRow(tone: .problem, symbol: "exclamationmark.triangle.fill", title: "ChatGPT sign-in unreadable",
                          detail: "Sign in again to repair it.") {
                    Button("Sign in with ChatGPT") { model.signIn() }
                        .buttonStyle(AppButtonStyle(kind: mainKind, small: !prominentSignIn))
                }
            }
        }
    }
}
