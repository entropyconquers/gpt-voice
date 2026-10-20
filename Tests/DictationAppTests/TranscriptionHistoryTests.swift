import AppKit
import DictationCore
import XCTest
@testable import GPTVoice

final class TranscriptionHistoryTests: XCTestCase {
    @MainActor
    func testRestoresExactTextDatesDestinationsAndDeletions() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("history.json")
        let older = HistoryEntry(text: "Use URLSession, then await the retry.\nKeep the newline.",
                                 createdAt: Date(timeIntervalSince1970: 1_000), delivery: .pasted(appName: "T3 Code"))
        let newer = HistoryEntry(text: "A copied thought.", createdAt: Date(timeIntervalSince1970: 2_000), delivery: .copied)
        let history = TranscriptionHistory(fileURL: url)
        await history.append(older)
        await history.append(newer)
        await history.append(newer)
        XCTAssertNil(history.errorMessage)
        XCTAssertEqual(history.entries, [newer, older])
        let restored = TranscriptionHistory(fileURL: url)
        await restored.waitForPendingChanges()
        XCTAssertEqual(restored.entries, [newer, older])
        await restored.remove(id: newer.id)
        let afterDelete = TranscriptionHistory(fileURL: url)
        await afterDelete.waitForPendingChanges()
        XCTAssertEqual(afterDelete.entries, [older])
        await afterDelete.clear()
        let afterClear = TranscriptionHistory(fileURL: url)
        await afterClear.waitForPendingChanges()
        XCTAssertTrue(afterClear.entries.isEmpty)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    }

    @MainActor
    func testUnreadableHistoryIsNotOverwritten() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("history.json")
        let original = Data("not a valid history document".utf8)
        try original.write(to: url)
        let history = TranscriptionHistory(fileURL: url)
        await history.waitForPendingChanges()
        XCTAssertNotNil(history.errorMessage)
        await history.append(HistoryEntry(text: "Keep the original file.", delivery: .copied))
        await history.clear()
        XCTAssertEqual(try Data(contentsOf: url), original)
        XCTAssertNotNil(history.errorMessage)
    }

    @MainActor
    func testFailedWriteCanBeRetriedWithoutLosingTheEntry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data().write(to: directory)
        let url = directory.appendingPathComponent("history.json")
        let history = TranscriptionHistory(fileURL: url)
        let entry = HistoryEntry(text: "Retry this save.", delivery: .clipboardPreserved)
        await history.append(entry)
        XCTAssertEqual(history.entries, [entry])
        XCTAssertNotNil(history.errorMessage)
        try FileManager.default.removeItem(at: directory)
        await history.retrySave()
        XCTAssertNil(history.errorMessage)
        let restored = TranscriptionHistory(fileURL: url)
        await restored.waitForPendingChanges()
        XCTAssertEqual(restored.entries, [entry])
    }

    @MainActor
    func testActualTranscriptionsAreSavedOnceButPracticeAndNoSpeechAreNot() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let history = TranscriptionHistory(fileURL: directory.appendingPathComponent("history.json"))
        let suite = "history-flow-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        preferences.automaticPaste = false
        let clipboard = NSPasteboard.withUniqueName()
        defer { clipboard.releaseGlobally() }
        let model = AppModel(preferences: preferences, pasteboard: clipboard, history: history) { url in
            if url.lastPathComponent == "empty.wav" { throw DictationError.emptyTranscript }
            return "Make the webhook handler idempotent."
        }
        defer { model.cleanup() }
        model.transcribeFile(URL(fileURLWithPath: "/practice.wav"), forPractice: true)
        try await waitUntil { model.phase == .finished(.previewed) }
        await history.waitForPendingChanges()
        XCTAssertTrue(history.entries.isEmpty)
        model.transcribeFile(URL(fileURLWithPath: "/actual.wav"))
        try await waitUntil { model.phase == .finished(.copied(.automaticPasteOff)) }
        XCTAssertEqual(history.entries.count, 1)
        XCTAssertEqual(history.entries.first?.delivery, .copied)
        model.copyLastTranscript()
        model.copyTranscript(history.entries[0].text)
        XCTAssertEqual(clipboard.string(forType: .string), history.entries[0].text)
        XCTAssertEqual(history.entries.count, 1)
        model.transcribeFile(URL(fileURLWithPath: "/empty.wav"))
        try await waitUntil { if case .failed = model.phase { return true }; return false }
        XCTAssertEqual(history.entries.count, 1)
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let limit = Date().addingTimeInterval(3)
        while !condition(), Date() < limit { try await Task.sleep(nanoseconds: 10_000_000) }
        XCTAssertTrue(condition())
    }
}
