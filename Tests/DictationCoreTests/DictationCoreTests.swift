import XCTest
@testable import DictationCore

final class DictationCoreTests: XCTestCase {
    func testRejectsAPIKeySignIn() {
        XCTAssertThrowsError(try CodexCredentials.decode(Data(#"{"auth_mode":"apikey","OPENAI_API_KEY":"test"}"#.utf8)))
    }

    func testReadsExistingChatGPTSignInAndExpiry() throws {
        let payload = Data(#"{"exp":1}"#.utf8).base64EncodedString()
        let data = try JSONSerialization.data(withJSONObject: ["auth_mode": "chatgpt", "tokens": ["access_token": "header.\(payload).signature", "account_id": "test-account"]])
        let credentials = try CodexCredentials.decode(data)
        XCTAssertEqual(credentials.accountID, "test-account")
        XCTAssertTrue(credentials.needsRefresh)
    }

    func testMissingCredentialsGivesSignInInstruction() {
        XCTAssertThrowsError(try CodexCredentials.load(from: URL(fileURLWithPath: "/absent-codex-dictation-auth"))) {
            XCTAssertTrue($0.localizedDescription.contains("codex login"))
        }
    }

    func testMultipartPreservesAudioBytesAndLanguage() {
        let bytes = Data([0, 13, 10, 255, 2])
        let multipart = MultipartAudio(audio: bytes, filename: "dictation.wav", contentType: "audio/wav", language: "en", boundary: "test-boundary")
        XCTAssertNotNil(multipart.body.range(of: bytes))
        XCTAssertNotNil(multipart.body.range(of: Data("name=\"language\"\r\n\r\nen\r\n".utf8)))
        XCTAssertTrue(multipart.body.suffix(Data("--test-boundary--\r\n".utf8).count) == Data("--test-boundary--\r\n".utf8))
    }

    func testMultipartRemovesHeaderInjectionFromFilename() {
        let multipart = MultipartAudio(audio: Data([1]), filename: "x\"\r\nInjected: true.wav", contentType: "audio/wav")
        let text = String(decoding: multipart.body, as: UTF8.self)
        XCTAssertFalse(text.contains("\r\nInjected:"))
    }

    func testServiceErrorsDoNotExposeResponseOrCredentials() {
        XCTAssertEqual(DictationError.service(429).localizedDescription, "ChatGPT reached a request limit. Try again later.")
        XCTAssertTrue(DictationError.service(403).localizedDescription.contains("denied"))
    }
}
