import Foundation

struct HistoryDocument: Codable {
    let version: Int
    let entries: [HistoryEntry]
}
