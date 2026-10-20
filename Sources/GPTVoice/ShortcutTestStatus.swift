import Foundation

enum ShortcutTestStatus: Equatable {
    case idle
    case listening
    case received
    case unavailable(String)
}
