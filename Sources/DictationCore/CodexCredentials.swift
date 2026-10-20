import Foundation

public struct CodexCredentials: Sendable {
    let accessToken: String
    let accountID: String
    let expiresAt: Date?

    public var needsRefresh: Bool {
        expiresAt.map { $0.timeIntervalSinceNow < 60 } ?? false
    }

    public static var authFile: URL {
        let environment = ProcessInfo.processInfo.environment
        let directory = environment["CODEX_HOME"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        return directory.appendingPathComponent("auth.json")
    }

    public static func load(from file: URL = authFile) throws -> CodexCredentials {
        guard FileManager.default.fileExists(atPath: file.path) else { throw DictationError.signInRequired }
        guard let data = try? Data(contentsOf: file) else { throw DictationError.invalidCredentials }
        return try decode(data)
    }

    static func decode(_ data: Data) throws -> CodexCredentials {
        guard let auth = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              auth["auth_mode"] as? String == "chatgpt",
              let tokens = auth["tokens"] as? [String: Any],
              let token = tokens["access_token"] as? String,
              let account = tokens["account_id"] as? String,
              !token.isEmpty, !account.isEmpty else { throw DictationError.signInRequired }
        return from(token: token, accountID: account)
    }

    static func from(token: String, accountID: String) -> CodexCredentials {
        let payload = jwtPayload(token)
        let expiresAt = (payload?["exp"] as? Double).map { Date(timeIntervalSince1970: $0) }
        return CodexCredentials(accessToken: token, accountID: accountID, expiresAt: expiresAt)
    }

    static func jwtPayload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
