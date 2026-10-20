import AppKit
import Combine
import DictationCore
import XCTest
@testable import GPTVoice

final class NoSpeechTests: XCTestCase {
    @MainActor
    func testNoSpeechDoesNotKeepAudioForRetryOrChangeTheClipboard() async throws {
        let suite = "no-speech-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let clipboard = NSPasteboard.withUniqueName()
        clipboard.setString("Keep my clipboard", forType: .string)
        let model = AppModel(preferences: AppPreferences(defaults: defaults), pasteboard: clipboard) { _ in
            throw DictationError.emptyTranscript
        }
        defer {
            model.cleanup()
            clipboard.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
        }
        let failed = expectation(description: "No speech result")
        let observer = model.$phase.sink { phase in
            if case .failed = phase { failed.fulfill() }
        }
        defer { observer.cancel() }

        model.transcribeFile(URL(fileURLWithPath: "/no-speech-check.wav"))
        await fulfillment(of: [failed], timeout: 2)

        guard case .failed(let failure) = model.phase else { return XCTFail("Expected no speech result") }
        XCTAssertEqual(failure.overlayMessage, "No speech found")
        XCTAssertFalse(model.canRetry)
        XCTAssertTrue(model.canStart)
        XCTAssertFalse(model.isPasteLeasePending)
        XCTAssertEqual(clipboard.string(forType: .string), "Keep my clipboard")
    }
}
