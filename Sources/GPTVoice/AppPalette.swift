import AppKit
import SwiftUI

/// Neutral color roles. Light: soft gray paper. Dark: neutral charcoal, no blue tint.
/// Color is used only for meaning: selection (accent), recording, success, warning, problem.
enum AppPalette {
    static let canvas = dynamic(light: 0xF4F4F3, dark: 0x1C1C1E)
    static let sidebar = dynamic(light: 0xEBEBEA, dark: 0x161617)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x252527)
    /// Recessed fills: toggle tracks, segment backgrounds, selection, hover.
    static let well = dynamic(light: 0xE6E6E4, dark: 0x303033)
    static let hairline = Color(nsColor: NSColor(name: nil) { appearance in
        isDark(appearance) ? NSColor.white.withAlphaComponent(0.09) : NSColor.black.withAlphaComponent(0.09)
    })

    /// Live recording only.
    static let recording = dynamic(light: 0xD5432B, dark: 0xFF6A50)
    static let success = dynamic(light: 0x2C7A4B, dark: 0x62C48C)
    static let warning = dynamic(light: 0x935400, dark: 0xE6AE4A)
    /// Light #B3232F: about 5.3:1 on problemSoft #FDE1E3 (hand calculation).
    static let problem = dynamic(light: 0xB3232F, dark: 0xFF6B76)
    static let problemSoft = dynamic(light: 0xFDE1E3, dark: 0x3A1D20)

    static let nsCanvas = dynamicNS(light: 0xF4F4F3, dark: 0x1C1C1E)
    static let nsWell = dynamicNS(light: 0xE6E6E4, dark: 0x303033)
    static let nsSurface = dynamicNS(light: 0xFFFFFF, dark: 0x252527)

    private static func isDark(_ appearance: NSAppearance) -> Bool {
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: dynamicNS(light: light, dark: dark))
    }

    static func dynamicNS(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            rgb(isDark(appearance) ? dark : light)
        }
    }

    private static func rgb(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}
