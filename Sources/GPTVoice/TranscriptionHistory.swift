import Foundation

@MainActor
final class TranscriptionHistory: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var isLoading = true
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?
    private let repository: HistoryRepository
    private var pending: Task<Void, Never>?
    private var queuedChanges = 0

    static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GPT Voice", isDirectory: true)
            .appendingPathComponent("history.json")
    }

    init(fileURL: URL? = nil) {
        repository = HistoryRepository(fileURL: fileURL ?? Self.defaultFileURL)
        enqueue(.load)
    }

    func append(_ entry: HistoryEntry) async { await enqueue(.append(entry)).value }
    func remove(id: UUID) async { await enqueue(.remove(id)).value }
    func clear() async { await enqueue(.clear).value }
    func retrySave() async { await enqueue(.retry).value }
    func waitForPendingChanges() async { await pending?.value }

    @discardableResult
    private func enqueue(_ change: HistoryRepository.Change) -> Task<Void, Never> {
        let previous = pending
        queuedChanges += 1
        isUpdating = true
        let task = Task {
            await previous?.value
            let snapshot = await repository.perform(change)
            entries = snapshot.entries
            errorMessage = snapshot.errorMessage
            isLoading = false
            queuedChanges -= 1
            isUpdating = queuedChanges != 0
        }
        pending = task
        return task
    }
}
