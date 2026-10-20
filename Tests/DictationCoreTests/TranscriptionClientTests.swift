import XCTest
@testable import DictationCore

final class TranscriptionClientTests: XCTestCase {
    private func client(status: Int, body: String) -> TranscriptionClient {
        StubURLProtocol.response = (status, Data(body.utf8))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return TranscriptionClient(session: URLSession(configuration: config))
    }

    private let credentials = CodexCredentials.from(token: "test-only-token", accountID: "test-account")
    private let multipart = MultipartAudio(audio: Data([0, 1, 2]), filename: "test.wav", contentType: "audio/wav")

    func testTranscriptionUsesSharedAccountAndReturnsText() async throws {
        let client = client(status: 200, body: #"{"text":"A spoken command.","asset_pointer":"ignored"}"#)
        let result = try await client.request(multipart, credentials: credentials)
        XCTAssertEqual(result, "A spoken command.")
        let request = try XCTUnwrap(StubURLProtocol.lastRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://chatgpt.com/backend-api/transcribe")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "ChatGPT-Account-Id"), "test-account")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-only-token")
    }

    func testServerFailureKeepsStatusWithoutExposingResponseBody() async {
        let client = client(status: 403, body: #"{"detail":"private server data"}"#)
        do {
            _ = try await client.request(multipart, credentials: credentials)
            XCTFail("Expected a denied request")
        } catch {
            XCTAssertEqual(error.localizedDescription, DictationError.service(403).localizedDescription)
            XCTAssertFalse(error.localizedDescription.contains("private"))
        }
    }

    func testBlankTranscriptIsRecoverableFailure() async {
        let client = client(status: 200, body: #"{"text":"   "}"#)
        do {
            _ = try await client.request(multipart, credentials: credentials)
            XCTFail("Expected no speech error")
        } catch {
            XCTAssertEqual(error.localizedDescription, DictationError.emptyTranscript.localizedDescription)
        }
    }

    func testUnexpectedResponseIsRecoverableFailure() async {
        let client = client(status: 200, body: #"{"message":"unknown"}"#)
        do {
            _ = try await client.request(multipart, credentials: credentials)
            XCTFail("Expected unreadable response error")
        } catch {
            XCTAssertEqual(error.localizedDescription, DictationError.invalidResponse.localizedDescription)
        }
    }
}
