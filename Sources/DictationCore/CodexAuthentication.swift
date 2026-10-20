import Foundation

public enum CodexAuthentication {
    public static var cliAvailable: Bool { CodexTokenRefresh.executable != nil }

    public static func refresh() async throws -> CodexCredentials {
        try await CodexTokenRefresh.refresh()
    }

    public static func signIn(openURL: @escaping (URL) async -> Void) async throws {
        guard let executable = CodexTokenRefresh.executable else { throw DictationError.refreshUnavailable }
        let process = Process()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        func send(_ object: [String: Any]) throws {
            var data = try JSONSerialization.data(withJSONObject: object)
            data.append(0x0a)
            try input.fileHandleForWriting.write(contentsOf: data)
        }
        try process.run()
        let timeout = Task {
            try await Task.sleep(nanoseconds: 600_000_000_000)
            if process.isRunning { process.terminate() }
        }
        defer {
            timeout.cancel()
            try? input.fileHandleForWriting.close()
            if process.isRunning { process.terminate() }
        }
        try await withTaskCancellationHandler {
            try send(["id": 1, "method": "initialize", "params": [
                "clientInfo": ["name": "codex_dictation", "version": "0.1.0"],
                "capabilities": ["experimentalApi": true]
            ]])
            for try await line in output.fileHandleForReading.bytes.lines {
                try Task.checkCancellation()
                guard let data = line.data(using: .utf8),
                      let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                if message["error"] != nil { throw DictationError.signInFailed }
                if message["id"] as? Int == 1 {
                    try send(["method": "initialized"])
                    try send(["id": 2, "method": "account/login/start", "params": ["type": "chatgpt"]])
                } else if message["id"] as? Int == 2 {
                    guard let result = message["result"] as? [String: Any],
                          let address = result["authUrl"] as? String,
                          let url = URL(string: address), url.scheme == "https",
                          ["auth.openai.com", "auth.chatgpt.com", "chatgpt.com"].contains(url.host ?? "") else {
                        throw DictationError.signInFailed
                    }
                    await openURL(url)
                } else if message["method"] as? String == "account/login/completed" {
                    guard let params = message["params"] as? [String: Any],
                          params["success"] as? Bool == true else { throw DictationError.signInFailed }
                    return
                }
            }
            throw DictationError.signInFailed
        } onCancel: {
            if process.isRunning { process.terminate() }
        }
    }
}
