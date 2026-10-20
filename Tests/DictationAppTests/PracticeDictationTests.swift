import AppKit
import Combine
import XCTest
@testable import GPTVoice

final class PracticeDictationTests: XCTestCase {
    @MainActor
    func testPracticeShowsItsTextWithoutChangingTheClipboard() async throws {
        let defaults = UserDefaults(suiteName: "practice-test-\(UUID().uuidString)")!
        let preferences = AppPreferences(defaults: defaults)
        preferences.automaticPaste = true
        let clipboard = NSPasteboard.withUniqueName()
        clipboard.setString("Keep my clipboard", forType: .string)
        let model = AppModel(preferences: preferences, pasteboard: clipboard, history: TranscriptionHistory(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("gpt-voice-test-\(UUID().uuidString)/history.json"))) { _ in "A clear thought." }
        defer { model.cleanup(); clipboard.releaseGlobally() }
        let finished = expectation(description: "Practice result is visible")
        let observer = model.$phase.sink { phase in
            if phase == .finished(.previewed) { finished.fulfill() }
        }
        defer { observer.cancel() }

        model.transcribeFile(URL(fileURLWithPath: "/practice-check.wav"), forPractice: true)
        await fulfillment(of: [finished], timeout: 2)

        XCTAssertEqual(model.practiceTranscript, "A clear thought.")
        XCTAssertEqual(clipboard.string(forType: .string), "Keep my clipboard")
        XCTAssertFalse(model.isPasteLeasePending)
    }

    @MainActor
    func testLeavingPracticeRejectsALateTranscription() async throws {
        let preferences = AppPreferences(defaults: UserDefaults(suiteName: "practice-test-\(UUID().uuidString)")!)
        let clipboard = NSPasteboard.withUniqueName()
        clipboard.setString("Keep my clipboard", forType: .string)
        let started = expectation(description: "Transcription started")
        let returned = expectation(description: "Cancelled provider returned")
        let model = AppModel(preferences: preferences, pasteboard: clipboard, history: TranscriptionHistory(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("gpt-voice-test-\(UUID().uuidString)/history.json"))) { _ in
            started.fulfill()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            returned.fulfill()
            return "Late text"
        }
        defer { model.cleanup(); clipboard.releaseGlobally() }

        model.transcribeFile(URL(fileURLWithPath: "/practice-check.wav"), forPractice: true)
        await fulfillment(of: [started], timeout: 2)
        model.endPractice()
        await fulfillment(of: [returned], timeout: 2)
        await Task.yield()

        XCTAssertEqual(model.phase, .idle)
        XCTAssertNil(model.practiceTranscript)
        XCTAssertFalse(model.isPracticeSession)
        XCTAssertEqual(clipboard.string(forType: .string), "Keep my clipboard")
    }

    @MainActor
    func testRetryOfFailedPracticeStillUsesThePreview() async throws {
        let preferences = AppPreferences(defaults: UserDefaults(suiteName: "practice-test-\(UUID().uuidString)")!)
        let clipboard = NSPasteboard.withUniqueName()
        clipboard.setString("Keep my clipboard", forType: .string)
        let attempts = AttemptCounter()
        let model = AppModel(preferences: preferences, pasteboard: clipboard, history: TranscriptionHistory(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("gpt-voice-test-\(UUID().uuidString)/history.json"))) { _ in
            if await attempts.next() == 1 { throw URLError(.timedOut) }
            return "Second try"
        }
        defer { model.cleanup(); clipboard.releaseGlobally() }
        let failed = expectation(description: "Practice can retry")
        let finished = expectation(description: "Retry preview is ready")
        let observer = model.$phase.sink { phase in
            if case .failed = phase { failed.fulfill() }
            if phase == .finished(.previewed) { finished.fulfill() }
        }
        defer { observer.cancel() }

        model.transcribeFile(URL(fileURLWithPath: "/practice-check.wav"), forPractice: true)
        await fulfillment(of: [failed], timeout: 2)
        XCTAssertTrue(model.canRetry)
        model.retry()
        await fulfillment(of: [finished], timeout: 2)

        XCTAssertEqual(model.practiceTranscript, "Second try")
        XCTAssertEqual(clipboard.string(forType: .string), "Keep my clipboard")
    }
}

private actor AttemptCounter {
    private var count = 0
    func next() -> Int { count += 1; return count }
}
