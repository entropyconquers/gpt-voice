import Foundation

/// The result of delivering a transcript. The caller keeps the original transcript in memory in all cases.
enum PasteOutcome: Equatable {
    /// The practice result is visible in the app. The clipboard was not changed.
    case previewed
    enum ManualReason: Equatable {
        case automaticPasteOff
        case accessibilityMissing
        case targetChanged
        case noTarget
        case injectionFailed
    }

    /// Text was pasted into the original app.
    case pasted(appName: String?)
    /// Text is on the clipboard. The user must paste it.
    case copied(ManualReason)
    /// The clipboard changed during dictation. It was not replaced. Offer Copy.
    case preservedNewerClipboard

    var message: String {
        switch self {
        case .previewed:
            return "Practice text is ready. Your clipboard was not changed."
        case .pasted(let name):
            return name.map { "Pasted into \($0)." } ?? "Pasted."
        case .copied(.automaticPasteOff):
            return "Copied. Press ⌘V to paste."
        case .copied(.accessibilityMissing):
            return "Copied. Accessibility is off, so press ⌘V to paste."
        case .copied(.targetChanged):
            return "Copied. You changed apps, so automatic paste was skipped. Press ⌘V to paste."
        case .copied(.noTarget):
            return "Copied. No target app was found. Press ⌘V to paste."
        case .copied(.injectionFailed):
            return "Copied. Automatic paste failed. Press ⌘V to paste."
        case .preservedNewerClipboard:
            return "Your clipboard changed, so it was not replaced. Select Copy to copy the transcript."
        }
    }

}
