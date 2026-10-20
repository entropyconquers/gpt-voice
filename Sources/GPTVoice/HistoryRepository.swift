import Foundation

/// Serial disk owner. A failed write keeps the latest data in memory for Retry.
actor HistoryRepository {
    enum Change: Sendable {
        case load
        case append(HistoryEntry)
        case remove(UUID)
        case clear
        case retry
    }

    private let fileURL: URL
    private var entries: [HistoryEntry] = []
    private var loaded = false

    init(fileURL: URL) { self.fileURL = fileURL }

    func perform(_ change: Change) -> HistorySnapshot {
        do {
            if !loaded {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let document = try JSONDecoder().decode(HistoryDocument.self, from: Data(contentsOf: fileURL))
                    guard document.version == 1 else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    entries = document.entries.sorted { $0.createdAt > $1.createdAt }
                }
                loaded = true
            }
        } catch {
            return HistorySnapshot(entries: entries, errorMessage: "Could not read history. The saved file was kept. Try again.")
        }
        switch change {
        case .load: return HistorySnapshot(entries: entries, errorMessage: nil)
        case .append(let entry):
            if !entries.contains(where: { $0.id == entry.id }) {
                entries.append(entry)
                entries.sort { $0.createdAt > $1.createdAt }
            }
        case .remove(let id): entries.removeAll { $0.id == id }
        case .clear: entries.removeAll()
        case .retry: break
        }
        do {
            try save()
            return HistorySnapshot(entries: entries, errorMessage: nil)
        } catch {
            return HistorySnapshot(entries: entries, errorMessage: "Changes are not saved yet. Keep GPT Voice open and try again.")
        }
    }

    private func save() throws {
        let manager = FileManager.default
        let directory = fileURL.deletingLastPathComponent()
        try manager.createDirectory(at: directory, withIntermediateDirectories: true,
                                    attributes: [.posixPermissions: 0o700])
        let data = try JSONEncoder().encode(HistoryDocument(version: 1, entries: entries))
        // Set permissions before replacing the file, so no transcript is briefly world-readable.
        let temporary = directory.appendingPathComponent(".history-\(UUID().uuidString).tmp")
        defer { try? manager.removeItem(at: temporary) }
        guard manager.createFile(atPath: temporary.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteNoPermission)
        }
        try data.write(to: temporary)
        if manager.fileExists(atPath: fileURL.path) {
            _ = try manager.replaceItemAt(fileURL, withItemAt: temporary)
        } else {
            try manager.moveItem(at: temporary, to: fileURL)
        }
        try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
