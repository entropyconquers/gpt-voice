import XCTest
@testable import DictationCore

final class TranscriptTextTests: XCTestCase {
    func testAutomaticPasteRemovesLineBreaksAndTerminalControls() {
        let text = TranscriptText.forAutomaticPaste("List files\r\nthen explain\u{1b}the result\n")
        XCTAssertEqual(text, "List files then explain the result")
        XCTAssertTrue(text.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) })
    }

    func testAutomaticPastePreservesPunctuationAndUnicode() {
        XCTAssertEqual(TranscriptText.forAutomaticPaste("Fix ‘café’ — please."), "Fix ‘café’ — please.")
    }
}
