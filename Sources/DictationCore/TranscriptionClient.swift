import Foundation

public final class TranscriptionClient {
    static let endpoint = URL(string: "https://chatgpt.com/backend-api/transcribe")!
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 110
        configuration.httpShouldSetCookies = false
        session = URLSession(configuration: configuration, delegate: NoRedirectDelegate(), delegateQueue: nil)
    }

    init(session: URLSession) { self.session = session }

    public func transcribe(file: URL, language: String? = nil) async throws -> String {
        let types = ["wav": "audio/wav", "m4a": "audio/mp4", "mp4": "audio/mp4", "mp3": "audio/mpeg",
                     "webm": "audio/webm", "ogg": "audio/ogg", "flac": "audio/flac"]
        guard let contentType = types[file.pathExtension.lowercased()] else { throw DictationError.invalidAudio }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        guard let size = attributes[.size] as? NSNumber, size.intValue > 0 else { throw DictationError.invalidAudio }
        guard size.intValue < 20_000_000 else { throw DictationError.audioTooLarge }
        let audio = try Data(contentsOf: file)
        let multipart = MultipartAudio(audio: audio, filename: "dictation.\(file.pathExtension.lowercased())",
                                       contentType: contentType, language: language)
        let current = try CodexCredentials.load()
        let credentials = current.needsRefresh ? try await CodexTokenRefresh.refresh() : current
        do {
            return try await request(multipart, credentials: credentials)
        } catch DictationError.service(401) {
            try Task.checkCancellation()
            return try await request(multipart, credentials: CodexTokenRefresh.refresh())
        }
    }

    func request(_ multipart: MultipartAudio, credentials: CodexCredentials) async throws -> String {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(credentials.accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        request.setValue("multipart/form-data; boundary=\(multipart.boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("GPTVoice", forHTTPHeaderField: "User-Agent")
        request.setValue("codex_dictation", forHTTPHeaderField: "originator")
        request.httpBody = multipart.body
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw DictationError.invalidResponse }
        guard response.statusCode == 200 else { throw DictationError.service(response.statusCode) }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = object["text"] as? String else { throw DictationError.invalidResponse }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DictationError.emptyTranscript }
        return text
    }
}
