import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case requiresApproval
    case disabled

    /// `.notFound` can mean the system has not seen an unregistered service yet, so it maps to disabled.
    /// A real registration problem appears as an error from `register()`.
    static func current() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notRegistered, .notFound: return .disabled
        @unknown default: return .disabled
        }
    }

    var isOn: Bool { self == .enabled || self == .requiresApproval }

    var detail: String? {
        switch self {
        case .enabled, .disabled: return nil
        case .requiresApproval: return "Allow GPT Voice in Login Items to finish."
        }
    }
}
