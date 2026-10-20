import Foundation

struct MultipartAudio {
    let boundary: String
    let body: Data

    init(audio: Data, filename: String, contentType: String, language: String? = nil,
         boundary: String = "----codex-dictation-\(UUID().uuidString)") {
        self.boundary = boundary
        var result = Data()
        func append(_ value: String) { result.append(Data(value.utf8)) }
        let name = filename.replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(name)\"\r\n")
        append("Content-Type: \(contentType)\r\n\r\n")
        result.append(audio)
        append("\r\n")
        if let language, !language.isEmpty {
            append("--\(boundary)\r\nContent-Disposition: form-data; name=\"language\"\r\n\r\n\(language)\r\n")
        }
        append("--\(boundary)--\r\n")
        body = result
    }
}
