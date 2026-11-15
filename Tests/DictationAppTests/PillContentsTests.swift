import XCTest
@testable import GPTVoice

final class PillContentsTests: XCTestCase {
    @MainActor
    func testPreferencesDefaultPersistAndRecoverFromInvalidData() {
        let suite = "pill-preferences-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        XCTAssertEqual(preferences.pillContents, .standard)
        preferences.pillContents = .minimal
        XCTAssertEqual(AppPreferences(defaults: defaults).pillContents, .minimal)
        defaults.set(Data("invalid".utf8), forKey: "pillContents")
        XCTAssertEqual(AppPreferences(defaults: defaults).pillContents, .standard)
    }

    func testAnEmptyConfigurationStillShowsRecording() throws {
        let contents = PillContents(waveform: false, timer: false, recordingDot: false,
                                    cancelButton: false, stopButton: false, statusText: false)
        XCTAssertTrue(contents.showsWaveform)
        XCTAssertEqual(try JSONDecoder().decode(PillContents.self, from: JSONEncoder().encode(contents)), contents)
    }

    func testWaveformCanBeHiddenWhenTimerOrDotIsVisible() {
        var contents = PillContents.standard
        contents.waveform = false
        XCTAssertFalse(contents.showsWaveform)
        contents.timer = false
        XCTAssertFalse(contents.showsWaveform)
        contents.recordingDot = false
        XCTAssertTrue(contents.showsWaveform)
    }
}
