import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let createdAt: Date
    let delivery: HistoryDelivery

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), delivery: HistoryDelivery) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.delivery = delivery
    }
}
