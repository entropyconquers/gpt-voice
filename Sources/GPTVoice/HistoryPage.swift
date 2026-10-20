import SwiftUI

/// History: saved transcripts grouped by day, newest first. Each can be copied or deleted.
/// Clear all sits beside the page title. Works during dictation, except Copy while a paste holds the clipboard.
struct HistoryPage: View {
    @ObservedObject var model: AppModel
    @ObservedObject var history: TranscriptionHistory
    @State private var pendingDeletion: HistoryEntry?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel) {
        self.model = model
        self.history = model.history
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let message = history.errorMessage {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    ErrorMessage(text: message)
                    Spacer(minLength: 8)
                    Button("Try again") { Task { await history.retrySave() } }
                        .buttonStyle(AppButtonStyle(kind: .secondary, isLoading: history.isUpdating, small: true))
                        .disabled(history.isUpdating)
                }
            }

            if history.isLoading {
                HStack(spacing: 8) {
                    ActivityIndicator(size: 11)
                    Text("Loading").font(AppType.detail).foregroundStyle(.secondary)
                }
            } else if history.entries.isEmpty {
                // After a read error the message above is the whole state, so no "empty" claim.
                if history.errorMessage == nil { empty }
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(days, id: \.day) { day in
                        HistoryDayView(day: day.day, entries: day.entries,
                                       canCopy: !model.isPasteLeasePending,
                                       copy: copy, delete: { pendingDeletion = $0 })
                    }
                }
            }
        }
        .animation(AppMotion.reveal(reduceMotion), value: history.entries)
        .confirmationDialog("Delete this transcript?",
                            isPresented: Binding(get: { pendingDeletion != nil },
                                                 set: { if !$0 { pendingDeletion = nil } }),
                            titleVisibility: .visible,
                            presenting: pendingDeletion) { entry in
            Button("Delete", role: .destructive) { Task { await history.remove(id: entry.id) } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var empty: some View {
        SettingsGroup {
            VStack(alignment: .leading, spacing: 4) {
                Text("No transcripts yet").font(AppType.rowTitle)
                Text("Dictate with \(model.preferences.hotkey.displayLabel). Each transcript is saved here, on this Mac.")
                    .font(AppType.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 16)
        }
    }

    /// Entries arrive newest first, so each day is one contiguous run.
    private var days: [(day: Date, entries: [HistoryEntry])] {
        let calendar = Calendar.current
        var result: [(day: Date, entries: [HistoryEntry])] = []
        for entry in history.entries {
            let day = calendar.startOfDay(for: entry.createdAt)
            if result.last?.day == day {
                result[result.count - 1].entries.append(entry)
            } else {
                result.append((day, [entry]))
            }
        }
        return result
    }

    /// The model also refuses during a paste lease. Checking here keeps the check mark honest.
    private func copy(_ entry: HistoryEntry) -> Bool {
        guard !model.isPasteLeasePending else { return false }
        model.copyTranscript(entry.text)
        return true
    }
}
