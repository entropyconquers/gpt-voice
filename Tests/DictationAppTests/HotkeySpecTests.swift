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
        XCTAssertEqual(HotkeySpec(keyCode: UInt16(kVK_Option), cocoaModifiers: .option).problem, .modifierOnly)
    }

    func testLeftOptionTapIsAShortcut() throws {
        XCTAssertNil(HotkeySpec.leftOption.problem)
        XCTAssertTrue(HotkeySpec.leftOption.isModifierHold)
        XCTAssertEqual(HotkeySpec.leftOption.displayLabel, "Left ⌥")
        XCTAssertEqual(HotkeySpec.leftOption.accessibilityLabel, "Left Option")
        XCTAssertEqual(HotkeySpec.leftOption.keycaps, ["Left ⌥"])
        let data = try JSONEncoder().encode(HotkeySpec.leftOption)
        XCTAssertEqual(try JSONDecoder().decode(HotkeySpec.self, from: data), .leftOption)
    }

    func testOtherModifierTapsAreDistinctFromChords() {
        for code in [kVK_RightOption, kVK_Control, kVK_RightControl, kVK_Shift, kVK_RightShift, kVK_Function] {
            let tap = HotkeySpec(keyCode: UInt32(code), modifiers: 0)
            XCTAssertNil(tap.problem)
            XCTAssertTrue(tap.isModifierHold)
            XCTAssertEqual(tap.keycaps.count, 1)
        }
        XCTAssertEqual(HotkeySpec(keyCode: UInt32(kVK_Command), modifiers: 0).problem, .modifierOnly)
        XCTAssertFalse(HotkeySpec(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey)).isModifierHold)
    }

    func testDeviceFlagsDistinguishLeftOptionFromAChord() {
        let leftOption: UInt = 0x0000_0020
        let independentOption: UInt = 0x0008_0000
        XCTAssertEqual(HotkeySpec.keyCode(forDeviceMask: leftOption), UInt32(kVK_Option))
        XCTAssertEqual(HotkeySpec.deviceMask(for: UInt32(kVK_Option)), leftOption)
        XCTAssertTrue(HotkeySpec.isSoleDeviceModifier(keyCode: UInt32(kVK_Option), rawFlags: leftOption | independentOption))
        XCTAssertFalse(HotkeySpec.isSoleDeviceModifier(keyCode: UInt32(kVK_Option), rawFlags: leftOption | 0x0000_0040))
        XCTAssertTrue(HotkeySpec.hasOtherDeviceModifier(than: UInt32(kVK_Option), rawFlags: leftOption | 0x0000_0002))
        XCTAssertFalse(HotkeySpec.hasOtherDeviceModifier(than: UInt32(kVK_Option), rawFlags: leftOption | 0x0001_0000))
    }
}
