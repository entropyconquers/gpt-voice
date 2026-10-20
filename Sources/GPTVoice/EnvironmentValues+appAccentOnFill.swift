import SwiftUI

extension EnvironmentValues {
    /// Text and symbol color for content placed on `appAccentFill`.
    var appAccentOnFill: Color {
        get { self[AppAccentOnFillKey.self] }
        set { self[AppAccentOnFillKey.self] = newValue }
    }
}
