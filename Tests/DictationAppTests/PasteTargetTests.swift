import XCTest
@testable import GPTVoice

final class PasteTargetTests: XCTestCase {
    func testSameFrontmostAppStillAcceptsDelivery() {
        XCTAssertTrue(PasteTarget.deliveryStillValid(capturedPID: 40, frontmostPID: 40))
    }

    func testADifferentFrontmostAppDoesNotAcceptDelivery() {
        XCTAssertFalse(PasteTarget.deliveryStillValid(capturedPID: 40, frontmostPID: 41))
        XCTAssertFalse(PasteTarget.deliveryStillValid(capturedPID: 40, frontmostPID: nil))
    }
}
