import AppKit
import SwiftUI

/// Accessibility row for automatic paste. Optional, so it never uses a warning tone.
/// While access is missing, a disclosure covers a grant that macOS no longer matches to this build.
struct AccessibilityCard: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences
    var offersManualPaste = false

    @State private var recoveryExpanded = false
    @FocusState private var recoveryFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel, offersManualPaste: Bool = false) {
        self.model = model
        self.preferences = model.preferences
        self.offersManualPaste = offersManualPaste
    }

    var body: some View {
        if model.accessibilityTrusted {
            StatusRow(tone: .good, symbol: "checkmark.circle.fill", title: "Accessibility",
                      detail: preferences.automaticPaste ? "" : "Automatic paste is off.", value: "Allowed") {
                if !preferences.automaticPaste {
                    Button("Turn on paste") { model.setAutomaticPaste(true) }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                }
            }
        } else if !preferences.automaticPaste {
            StatusRow(tone: .neutral, symbol: "doc.on.clipboard", title: "Manual paste",
                      detail: "Text is copied. You press ⌘V.") {
                Button("Use automatic paste") { model.setAutomaticPaste(true) }
                    .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                StatusRow(tone: .neutral, symbol: "circle.dashed", title: "Accessibility",
                          detail: "Optional. Lets the app paste for you.") {
                    Button("Allow") { model.requestAccessibility() }
                        .buttonStyle(AppButtonStyle(kind: .secondary, small: true))
                        .accessibilityLabel("Allow Accessibility")
                    Button("Open Settings") { model.openAccessibilitySettings() }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                        .accessibilityLabel("Open Accessibility settings")
                    QuietIconButton(symbol: "arrow.clockwise", label: "Check Accessibility again") {
                        model.refreshStatus()
                    }
                }
                recovery
                    .padding(.leading, 26)
                    .padding(.top, -4)
                    .padding(.bottom, offersManualPaste ? 4 : 12)
                if offersManualPaste {
                    Button("Skip and use manual paste") { model.setAutomaticPaste(false) }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                        .padding(.leading, 16)
                        .padding(.bottom, 10)
                }
            }
        }
    }

    /// Same look and semantics as `InfoDisclosure`, with one action inside.
    private var recovery: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                recoveryExpanded.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(recoveryExpanded ? 90 : 0))
                    Text("Already turned on?").font(AppType.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focused($recoveryFocused)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                    .padding(-3)
                    .opacity(recoveryFocused ? 1 : 0)
            )
            .accessibilityValue(recoveryExpanded ? "Expanded" : "Collapsed")

            if recoveryExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("After an update, macOS can keep an old entry that no longer matches this app. In System Settings, remove GPT Voice with −, add this app with +, then reopen GPT Voice.")
                        .font(AppType.detail)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 520, alignment: .leading)
                    Button("Show this app") { model.revealAppInFinder() }
                        .buttonStyle(AppButtonStyle(kind: .quiet, small: true))
                        .accessibilityLabel("Show GPT Voice in Finder")
                        .padding(.leading, -10)
                }
                .padding(.leading, 14)
                .transition(.opacity)
            }
        }
        .animation(AppMotion.control(reduceMotion), value: recoveryExpanded)
    }
}
