import AppKit
import Carbon.HIToolbox
import XCTest
@testable import GPTVoice

final class HotkeySpecTests: XCTestCase {
    func testCommandSpaceCanBeChosenWhenTheSystemShortcutIsDisabled() {
        XCTAssertNil(HotkeySpec.commandSpace.problem)
        XCTAssertEqual(HotkeySpec.commandSpace.displayLabel, "⌘Space")
    }

    func testConfigurableSystemCombinationsAreNotPermanentlyBlocked() {
        for modifiers in [controlKey, cmdKey | optionKey, controlKey | cmdKey] {
            XCTAssertNil(HotkeySpec(keyCode: UInt32(kVK_Space), modifiers: UInt32(modifiers)).problem)
        }
    }

    func testEditingAndQuitShortcutsRemainProtected() {
        for code in [kVK_ANSI_Q, kVK_ANSI_V, kVK_ANSI_C, kVK_ANSI_Z] {
            XCTAssertEqual(HotkeySpec(keyCode: UInt32(code), modifiers: UInt32(cmdKey)).problem, .reserved)
        }
    }

    func testCommandSpaceRoundTripKeepsItsKeyAndModifiers() throws {
        let data = try JSONEncoder().encode(HotkeySpec.commandSpace)
        let restored = try JSONDecoder().decode(HotkeySpec.self, from: data)
        XCTAssertEqual(restored, .commandSpace)
        XCTAssertEqual(restored.accessibilityLabel, "Command Space")
    }

    func testPlainSpaceAndModifierKeysAreRejected() {
        XCTAssertEqual(HotkeySpec(keyCode: UInt32(kVK_Space), modifiers: 0).problem, .needsModifier)
        XCTAssertEqual(HotkeySpec(keyCode: UInt32(kVK_Command), modifiers: UInt32(cmdKey)).problem, .modifierOnly)
    }
}
