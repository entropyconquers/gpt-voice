import Carbon.HIToolbox
import XCTest
@testable import GPTVoice

final class ModifierHoldTrackerTests: XCTestCase {
    private let leftOption = UInt32(kVK_Option)

    func testAHoldStartsOnlyAfterCommitAndEndsOnRelease() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertTrue(tracker.commit())
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: false, otherModifierDown: false,
                                       cancelsHold: false), .end)
    }

    func testReleaseBeforeCommitDoesNotEndTheHold() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: false, otherModifierDown: false,
                                       cancelsHold: false), .disarm)
        XCTAssertFalse(tracker.commit())
    }

    func testAnotherKeyBeforeCommitDisarmsWithoutCancellingASession() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertEqual(tracker.chordFromKey(), .disarm)
        XCTAssertFalse(tracker.commit())
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: false, otherModifierDown: false,
                                       cancelsHold: false), .none)
    }

    func testAnotherKeyAfterCommitCancelsTheSession() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertTrue(tracker.commit())
        XCTAssertEqual(tracker.chordFromKey(), .cancelSession)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: false, otherModifierDown: false,
                                       cancelsHold: false), .none)
    }

    func testAClickBeforeCommitDisarmsButAClickDuringRecordingDoesNot() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertEqual(tracker.pointer(), .disarm)

        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertTrue(tracker.commit())
        XCTAssertEqual(tracker.pointer(), .none)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: false, otherModifierDown: false,
                                       cancelsHold: false), .end)
    }

    func testAnotherModifierCancelsThePendingHold() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: true, otherModifierDown: false,
                                       cancelsHold: false), .arm)
        XCTAssertEqual(tracker.consume(eventKeyCode: UInt32(kVK_Shift), modifierDown: false, otherModifierDown: true,
                                       cancelsHold: false), .disarm)
    }

    func testTheOtherOptionKeyDoesNotStartALeftOptionHold() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: UInt32(kVK_RightOption), modifierDown: true,
                                       otherModifierDown: false, cancelsHold: false), .none)
        XCTAssertEqual(tracker.consume(eventKeyCode: UInt32(kVK_RightOption), modifierDown: false,
                                       otherModifierDown: false, cancelsHold: false), .none)
    }

    func testReleaseWithoutAPressDoesNothing() {
        var tracker = ModifierHoldTracker(keyCode: leftOption)
        XCTAssertEqual(tracker.consume(eventKeyCode: leftOption, modifierDown: false, otherModifierDown: false,
                                       cancelsHold: false), .none)
    }
}
