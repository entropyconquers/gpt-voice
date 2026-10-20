import Foundation

struct HistorySnapshot: Sendable {
    let entries: [HistoryEntry]
    let errorMessage: String?
}
