import SwiftUI

/// Environment key for the accent fill role: backgrounds behind white content.
struct AppAccentFillKey: EnvironmentKey {
    static let defaultValue: Color = .accentColor
}
