import Foundation

public enum TranscriptText {
    public static func forAutomaticPaste(_ text: String) -> String {
        let separators = CharacterSet.controlCharacters.union(.newlines)
        return text.components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
