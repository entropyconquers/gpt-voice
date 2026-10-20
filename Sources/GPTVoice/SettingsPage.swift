import Foundation

enum SettingsPage: String, CaseIterable, Identifiable {
    case home
    case history
    case shortcuts
    case appearance
    case preferences
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .shortcuts: return "Shortcut"
        case .appearance: return "Appearance"
        case .preferences: return "Preferences"
        case .privacy: return "Privacy"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .history: return "clock.arrow.circlepath"
        case .shortcuts: return "command"
        case .appearance: return "circle.lefthalf.filled"
        case .preferences: return "slider.horizontal.3"
        case .privacy: return "hand.raised"
        }
    }

    /// A subtitle only where the title alone does not explain the page.
    var intro: String? {
        switch self {
        case .shortcuts: return "Press it once to start dictation. Press it again to stop."
        case .home, .history, .appearance, .preferences, .privacy: return nil
        }
    }
}
