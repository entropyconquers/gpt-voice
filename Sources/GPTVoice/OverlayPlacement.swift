import Foundation

/// Where the dictation overlay appears on the current screen.
enum OverlayPlacement: String, CaseIterable, Identifiable {
    case bottom
    case top

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bottom: return "Bottom"
        case .top: return "Top"
        }
    }
}
