import Foundation

enum HistoryDelivery: Codable, Equatable, Sendable {
    /// The app sent paste keystrokes. The destination can still reject them.
    case pasted(appName: String?)
    case copied
    case clipboardPreserved

    init(_ outcome: PasteOutcome) {
        switch outcome {
        case .pasted(let name): self = .pasted(appName: name)
        case .preservedNewerClipboard: self = .clipboardPreserved
        case .copied, .previewed: self = .copied
        }
    }
}
