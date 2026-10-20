import Carbon.HIToolbox
import XCTest
@testable import GPTVoice

final class GlobalShortcutTests: XCTestCase {
    @MainActor
    func testFailedReplacementKeepsThePreviousShortcut() async throws {
        let first = GlobalShortcut(onPress: {})
        let second = GlobalShortcut(onPress: {})
        defer { first.unregister(); second.unregister() }
        let a = HotkeySpec(keyCode: UInt32(kVK_F19), modifiers: UInt32(controlKey | optionKey | shiftKey))
        let b = HotkeySpec(keyCode: UInt32(kVK_F20), modifiers: UInt32(controlKey | optionKey | shiftKey))
        try first.replace(with: a)
        try second.replace(with: b)
        XCTAssertThrowsError(try second.replace(with: a))
        XCTAssertEqual(second.current, b)
    }

    @MainActor
    func testCommandSpaceUsesCurrentSystemSettings() async throws {
        let shortcut = GlobalShortcut(onPress: {})
        defer { shortcut.unregister() }
        if GlobalShortcut.isSystemShortcutEnabled(.commandSpace) {
            XCTAssertThrowsError(try shortcut.replace(with: .commandSpace)) { error in
                XCTAssertEqual(error as? GlobalShortcut.RegistrationError, .systemShortcut(.commandSpace))
            }
        } else {
            do {
                try shortcut.replace(with: .commandSpace)
                XCTAssertEqual(shortcut.current, .commandSpace)
            } catch GlobalShortcut.RegistrationError.conflict {
                throw XCTSkip("Another app currently owns Command–Space.")
            }
        }
    }
}
