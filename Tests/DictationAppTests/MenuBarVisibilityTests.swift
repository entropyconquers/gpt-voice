import AppKit
import XCTest
@testable import GPTVoice

final class MenuBarVisibilityTests: XCTestCase {
    @MainActor
    func testDefaultsToVisibleAndPersistsHiddenChoice() {
        let suite = "menu-bar-preference-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        XCTAssertTrue(preferences.showMenuBarIcon)
        preferences.showMenuBarIcon = false
        XCTAssertFalse(AppPreferences(defaults: defaults).showMenuBarIcon)
        preferences.showMenuBarIcon = true
        XCTAssertTrue(AppPreferences(defaults: defaults).showMenuBarIcon)
    }

    @MainActor
    func testMenuItemVisibilityChangesWithoutRestarting() {
        let suite = "menu-bar-controller-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        preferences.showMenuBarIcon = false
        let history = TranscriptionHistory(fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("gpt-voice-test-\(UUID().uuidString)/history.json"))
        let model = AppModel(preferences: preferences, history: history)
        defer { model.cleanup() }
        let menu = StatusMenuController(model: model, windows: WindowCoordinator(model: model))
        XCTAssertFalse(menu.isVisible)
        preferences.showMenuBarIcon = true
        XCTAssertTrue(menu.isVisible)
        preferences.showMenuBarIcon = false
        XCTAssertFalse(menu.isVisible)
    }
}
