import Foundation

struct CodexTokenRefresh {
    static var executable: URL? {
        let searchPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let environmentPaths = searchPath.split(separator: ":").filter { $0.hasPrefix("/") }
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent("codex").path }
        let paths = ["/opt/homebrew/bin/codex", "/usr/local/bin/codex",
                     FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/codex").path]
            + environmentPaths
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }.map { URL(fileURLWithPath: $0) }
    }

    static func refresh() async throws -> CodexCredentials {
        guard let executable else { throw DictationError.refreshUnavailable }
        let process = Process()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        func send(_ object: [String: Any]) throws {
            var data = try JSONSerialization.data(withJSONObject: object)
            data.append(0x0a)
            try input.fileHandleForWriting.write(contentsOf: data)
        }
        try process.run()
        let timeout = Task {
            try await Task.sleep(nanoseconds: 30_000_000_000)
            if process.isRunning { process.terminate() }
        }
        defer {
            timeout.cancel()
            try? input.fileHandleForWriting.close()
            if process.isRunning { process.terminate() }
        }
        try send(["id": 1, "method": "initialize", "params": [
            "clientInfo": ["name": "codex_dictation", "version": "0.1.0"],
            "capabilities": ["experimentalApi": true]
        ]])
        return try await withTaskCancellationHandler {
          for try await line in output.fileHandleForReading.bytes.lines {
            try Task.checkCancellation()
            guard let data = line.data(using: .utf8),
                  let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = message["id"] as? Int else { continue }
            if message["error"] != nil { throw DictationError.refreshFailed }
            if id == 1 {
                try send(["method": "initialized"])
                try send(["id": 2, "method": "getAuthStatus", "params": ["includeToken": true, "refreshToken": true]])
            } else if id == 2 {
                guard let result = message["result"] as? [String: Any],
                      result["authMethod"] as? String == "chatgpt",
                      let token = result["authToken"] as? String, !token.isEmpty,
                      let claims = CodexCredentials.jwtPayload(token),
                      let auth = claims["https://api.openai.com/auth"] as? [String: Any],
                      let accountID = auth["chatgpt_account_id"] as? String else { throw DictationError.refreshFailed }
                return CodexCredentials.from(token: token, accountID: accountID)
            }
          }
          throw DictationError.refreshFailed
        } onCancel: {
            if process.isRunning { process.terminate() }
        }
    }
}
