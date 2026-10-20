import SwiftUI

/// Meaning of a status row. Each tone has a symbol and words, so color is never the only cue.
enum StatusTone {
    case good
    case attention
    case problem
    case working
    case neutral

    var color: Color {
        switch self {
        case .good: return AppPalette.success
        case .attention: return AppPalette.warning
        case .problem: return AppPalette.problem
        case .working, .neutral: return .secondary
        }
    }
}
