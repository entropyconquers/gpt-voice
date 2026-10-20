import SwiftUI

/// Motion tokens. Short and settled. No bounce anywhere. Reduce Motion removes movement.
enum AppMotion {
    /// Hover, press, toggle, segment: 0.16 s ease-out.
    static func control(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.16)
    }

    /// Page and step changes: a 0.22 s cross-fade. Movement stays at 6 pt or less.
    static func reveal(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.1) : .easeOut(duration: 0.22)
    }
}
