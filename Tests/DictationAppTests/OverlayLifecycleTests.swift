import AppKit
import Combine
import DictationCore
import XCTest
@testable import GPTVoice

final class OverlayLifecycleTests: XCTestCase {
    @MainActor
    func testNoSpeechKeepsItsContentDuringFadeThenDisappears() async throws {
        let fixture = Fixture()
        defer { fixture.cleanup() }
        fixture.controller.update(for: .failed(DictationFailure(transcriptionError: DictationError.emptyTranscript)))
        XCTAssertEqual(fixture.controller.displayedState, .message(label: "No speech found", kind: .noSpeech))
        XCTAssertTrue(fixture.controller.isVisible)

        try await waitUntil { fixture.controller.isExiting }
        XCTAssertEqual(fixture.controller.displayedState, .message(label: "No speech found", kind: .noSpeech))
        try await waitUntil { !fixture.controller.isVisible }
        XCTAssertEqual(fixture.controller.displayedState, .hidden)
    }

    @MainActor
    func testAnOldFadeCannotHideNewRecording() async throws {
        let fixture = Fixture()
        defer { fixture.cleanup() }
        fixture.controller.update(for: .finished(.copied(.automaticPasteOff)))
        try await waitUntil { fixture.controller.isExiting }

        fixture.controller.update(for: .recording)
        try await Task.sleep(nanoseconds: 350_000_000)

        XCTAssertTrue(fixture.controller.isVisible)
        XCTAssertFalse(fixture.controller.isExiting)
        XCTAssertEqual(fixture.controller.opacity, 1, accuracy: 0.01)
        guard case .recording = fixture.controller.displayedState else { return XCTFail("New recording was lost") }
    }

    @MainActor
    func testClosingHelpPersistsEvenWhenNewWorkInterruptsTheFade() async throws {
        let fixture = Fixture()
        defer { fixture.cleanup() }
        fixture.controller.update(for: .finished(.copied(.accessibilityMissing)))
        XCTAssertTrue(fixture.controller.displayedState.isHelp)

        fixture.controller.dismissHelp()
        fixture.controller.update(for: .recording)
        fixture.controller.update(for: .finished(.copied(.accessibilityMissing)))

        XCTAssertTrue(AppPreferences(defaults: fixture.defaults).manualPasteHelpDismissed)
        XCTAssertEqual(fixture.controller.displayedState, .message(label: "Press ⌘V to paste", kind: .info))
        try await waitUntil { !fixture.controller.isVisible }
    }

    @MainActor
    func testHelpAlsoExpiresButAnInterruptedExplanationIsNotAcknowledged() async throws {
        let fixture = Fixture()
        defer { fixture.cleanup() }
        fixture.controller.update(for: .finished(.copied(.accessibilityMissing)))
        fixture.controller.update(for: .recording)
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertTrue(fixture.controller.isVisible)
        XCTAssertFalse(fixture.model.preferences.manualPasteHelpDismissed)

        fixture.controller.update(for: .finished(.copied(.accessibilityMissing)))
        try await waitUntil { !fixture.controller.isVisible }
        XCTAssertTrue(fixture.model.preferences.manualPasteHelpDismissed)
    }

    @MainActor
    func testRepeatedCopyShowsTheHintAgainWithoutClearingTheResult() async throws {
        let fixture = Fixture()
        defer { fixture.cleanup() }
        fixture.model.preferences.automaticPaste = false
        fixture.model.transcribeFile(URL(fileURLWithPath: "/overlay-copy-check.wav"))
        try await waitUntil { fixture.model.phase == .finished(.copied(.automaticPasteOff)) }
        try await waitUntil { !fixture.controller.isVisible }

        fixture.model.copyLastTranscript()

        XCTAssertTrue(fixture.controller.isVisible)
        XCTAssertEqual(fixture.controller.displayedState, .message(label: "Press ⌘V to paste", kind: .info))
        XCTAssertEqual(fixture.clipboard.string(forType: .string), "Overlay test text")
        try await waitUntil { !fixture.controller.isVisible }
        XCTAssertEqual(fixture.model.phase, .finished(.copied(.automaticPasteOff)))
    }

    @MainActor
    func testResizingKeepsTheCentreAndTopEdgeFixed() async throws {
        let fixture = Fixture()
        defer { fixture.cleanup() }
        fixture.model.preferences.overlayPlacement = .top
        fixture.controller.update(for: .recording)
        let original = fixture.controller.targetFrame
        fixture.controller.update(for: .finished(.preservedNewerClipboard))
        let target = fixture.controller.targetFrame

        XCTAssertGreaterThan(target.width, original.width)
        XCTAssertEqual(target.midX, original.midX, accuracy: 0.5)
        XCTAssertEqual(target.maxY, original.maxY, accuracy: 0.5)
        try await waitUntil { abs(fixture.controller.frame.width - target.width) < 0.5 }
    }

    @MainActor
    func testWidthMovesThroughAnIntermediateFrame() async throws {
        let fixture = Fixture(resize: 0.4)
        defer { fixture.cleanup() }
        fixture.controller.update(for: .recording)
        let original = fixture.controller.frame.width
        fixture.controller.update(for: .pasting)
        let target = fixture.controller.targetFrame.width
        XCTAssertNotEqual(original, target)

        try await Task.sleep(nanoseconds: 120_000_000)
        let intermediate = fixture.controller.frame.width
        XCTAssertGreaterThan(intermediate, min(original, target))
        XCTAssertLessThan(intermediate, max(original, target))
        try await waitUntil { abs(fixture.controller.frame.width - target) < 0.5 }
    }

    @MainActor
    func testReduceMotionChangesSizeWithoutMovementAndStillFadesOut() async throws {
        let fixture = Fixture(reduceMotion: true)
        defer { fixture.cleanup() }
        fixture.controller.update(for: .recording)
        fixture.controller.update(for: .finished(.preservedNewerClipboard))
        XCTAssertEqual(fixture.controller.frame.width, fixture.controller.targetFrame.width, accuracy: 0.5)

        try await waitUntil { fixture.controller.isExiting }
        XCTAssertNotEqual(fixture.controller.displayedState, .hidden)
        try await waitUntil { !fixture.controller.isVisible }
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(2)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), "Overlay did not reach the expected state")
    }

    @MainActor
    private final class Fixture {
        let suite = "overlay-test-\(UUID().uuidString)"
        let defaults: UserDefaults
        let clipboard: NSPasteboard
        let model: AppModel
        let controller: DictationPanelController

        init(resize: TimeInterval = 0.12, reduceMotion: Bool = false) {
            _ = NSApplication.shared
            FontRegistration.registerBundledFonts()
            defaults = UserDefaults(suiteName: suite)!
            clipboard = NSPasteboard.withUniqueName()
            model = AppModel(preferences: AppPreferences(defaults: defaults), pasteboard: clipboard, history: TranscriptionHistory(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("gpt-voice-test-\(UUID().uuidString)/history.json"))) { _ in
                "Overlay test text"
            }
            let timing = OverlayTiming(resize: resize, entrance: 0.02, exit: 0.2, reducedFade: 0.1,
                                       success: 0.08, noSpeech: 0.08, warning: 0.08, pasteHint: 0.08, help: 0.08)
            controller = DictationPanelController(model: model, timing: timing, reduceMotion: { reduceMotion })
        }

        func cleanup() {
            controller.shutdown()
            model.cleanup()
            clipboard.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
        }
    }
}
