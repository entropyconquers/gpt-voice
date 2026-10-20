import SwiftUI

/// Clear all, beside the History title. Shown only when there is something to clear. Asks first, with the count.
struct HistoryClearView: View {
    @ObservedObject var history: TranscriptionHistory
    @State private var confirming = false
    @State private var clearing = false

    var body: some View {
        if !history.entries.isEmpty {
            Button("Clear all") { confirming = true }
                .buttonStyle(AppButtonStyle(kind: .quiet, isLoading: clearing, small: true))
                .disabled(clearing)
                .confirmationDialog(title, isPresented: $confirming, titleVisibility: .visible) {
                    Button("Delete all", role: .destructive, action: clear)
                    Button("Cancel", role: .cancel) {}
                }
        }
    }

    private var title: String {
        let count = history.entries.count
        return count == 1 ? "Delete 1 transcript?" : "Delete all \(count) transcripts?"
    }

    private func clear() {
        clearing = true
        Task {
            await history.clear()
            clearing = false
        }
    }
}
