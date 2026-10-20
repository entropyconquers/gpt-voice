import AppKit
import SwiftUI

/// One saved transcript: time and known destination, then the selectable text.
/// Long text stops at four lines with Show more. Copy confirms with a brief check in place.
struct HistoryEntryView: View {
    let entry: HistoryEntry
    let canCopy: Bool
    /// Returns false when nothing was copied.
    let copy: () -> Bool
    let delete: () -> Void

    @State private var expanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var clampedHeight: CGFloat = 0
    @State private var copied = false
    @State private var resetCopied: Task<Void, Never>?
    @FocusState private var toggleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let collapsedLines = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(meta)
                    .font(AppType.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    // Day headings say Today or Yesterday. The tooltip keeps the exact moment.
                    .help(entry.createdAt.formatted(date: .complete, time: .standard))
                Spacer(minLength: 8)
                HStack(spacing: 2) {
                    QuietIconButton(symbol: copied ? "checkmark" : "doc.on.doc",
                                    label: copied ? "Copied" : "Copy transcript",
                                    action: performCopy)
                        .disabled(!canCopy)
                        .opacity(canCopy ? 1 : 0.4)
                        .animation(AppMotion.control(reduceMotion), value: copied)
                    QuietIconButton(symbol: "trash", label: "Delete transcript", action: delete)
                }
            }

            Text(entry.text)
                .font(AppType.body)
                .lineSpacing(3)
                .lineLimit(expanded ? nil : Self.collapsedLines)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(measure { if !expanded { clampedHeight = $0 } })
                .background(alignment: .topLeading) {
                    // Unclamped copy at the same width, to know whether Show more is needed.
                    Text(entry.text)
                        .font(AppType.body)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .background(measure { fullHeight = $0 })
                        .accessibilityHidden(true)
                }

            if expanded || fullHeight > clampedHeight + 1 {
                expandToggle
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .animation(AppMotion.control(reduceMotion), value: expanded)
        .onDisappear { resetCopied?.cancel() }
    }

    /// Time, plus the app only when paste keystrokes went to a known one. "Sent", because the app may not accept them.
    private var meta: String {
        let time = entry.createdAt.formatted(date: .omitted, time: .shortened)
        if case .pasted(let appName?) = entry.delivery, !appName.isEmpty {
            return "\(time) · Sent to \(appName)"
        }
        return time
    }

    private var expandToggle: some View {
        Button(expanded ? "Show less" : "Show more") { expanded.toggle() }
            .buttonStyle(.plain)
            .font(AppType.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .focused($toggleFocused)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                    .padding(-3)
                    .opacity(toggleFocused ? 1 : 0)
            )
    }

    private func measure(_ update: @escaping (CGFloat) -> Void) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { update(proxy.size.height) }
                .onChange(of: proxy.size.height) { update($0) }
        }
    }

    private func performCopy() {
        guard copy() else { return }
        copied = true
        NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested,
                             userInfo: [.announcement: "Copied",
                                        .priority: NSAccessibilityPriorityLevel.high.rawValue])
        resetCopied?.cancel()
        resetCopied = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            copied = false
        }
    }
}
