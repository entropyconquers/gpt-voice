import SwiftUI

extension EnvironmentValues {
    /// The selected accent for fills behind white labels or symbols.
    var appAccentFill: Color {
        get { self[AppAccentFillKey.self] }
        set { self[AppAccentFillKey.self] = newValue }
    }
}
