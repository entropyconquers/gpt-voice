import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case permissions
    case shortcut
    case practice
    case ready

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .welcome: return "Connect"
        case .permissions: return "Access"
        case .shortcut: return "Shortcut"
        case .practice: return "Try it"
        case .ready: return "Ready"
        }
    }

    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
}
