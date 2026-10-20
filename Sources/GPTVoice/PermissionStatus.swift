import AVFoundation

enum PermissionStatus: Equatable {
    case granted
    case notRequested
    case denied
    case restricted

    init(_ status: AVAuthorizationStatus) {
        switch status {
        case .authorized: self = .granted
        case .notDetermined: self = .notRequested
        case .restricted: self = .restricted
        default: self = .denied
        }
    }

    var title: String {
        switch self {
        case .granted: return "Allowed"
        case .notRequested: return "Not requested"
        case .denied: return "Off"
        case .restricted: return "Restricted"
        }
    }
}
