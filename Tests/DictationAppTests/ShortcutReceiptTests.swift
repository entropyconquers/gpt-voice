import AppKit
import XCTest
@testable import GPTVoice

final class ShortcutReceiptTests: XCTestCase {
    @MainActor
    func testShortcutCheckDoesNotStartTheMicrophoneOrChangeTheClipboard() throws {
        let suite = "shortcut-receipt-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        let clipboard = NSPasteboard.withUniqueName()
        clipboard.setString("Keep my clipboard", forType: .string)
        let model = AppModel(preferences: preferences, pasteboard: clipboard)
        defer { model.cleanup(); clipboard.releaseGlobally() }
        model.activate()
        guard model.hotkeyError == nil else {
            throw XCTSkip("The test shortcut is owned by another app.")
        }

        model.beginShortcutTest()
        XCTAssertEqual(model.shortcutTestStatus, .listening)
        model.receiveGlobalShortcut()
        XCTAssertEqual(model.shortcutTestStatus, .received)
        XCTAssertEqual(model.phase, .idle)
        XCTAssertEqual(clipboard.string(forType: .string), "Keep my clipboard")

        // A repeated press stays in the test until it is explicitly closed.
        model.receiveGlobalShortcut()
        XCTAssertEqual(model.phase, .idle)
        model.endShortcutTest()
        XCTAssertEqual(model.shortcutTestStatus, .idle)
    }
}
