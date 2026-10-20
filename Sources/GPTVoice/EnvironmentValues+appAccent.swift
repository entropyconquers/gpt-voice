import SwiftUI

extension EnvironmentValues {
    /// The selected accent, foreground role: icons and indicators. For fills behind white content use `appAccentFill`.
    var appAccent: Color {
        get { self[AppAccentKey.self] }
        set { self[AppAccentKey.self] = newValue }
    }
}
