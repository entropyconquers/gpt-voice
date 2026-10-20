import AppKit
import SwiftUI

/// Accent choices. The accent marks selection and the main action. It never means error.
/// The stored value `system` is kept for saved preferences and now shows Graphite:
/// a near-black fill in light mode and a near-white fill in dark mode.
enum AccentChoice: String, CaseIterable, Identifiable {
    case system
    case blue
    case violet
    case rose
    case amber
    case green
    case teal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Graphite"
        case .blue: return "Blue"
        case .violet: return "Violet"
        case .rose: return "Rose"
        case .amber: return "Amber"
        case .green: return "Green"
        case .teal: return "Teal"
        }
    }

    /// Fill role for AppKit painting.
    var nsColor: NSColor {
        switch self {
        case .system: return AppPalette.dynamicNS(light: 0x1C1C1E, dark: 0xECECEC)
        case .blue: return NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 1)   // #2563EB
        case .violet: return NSColor(srgbRed: 0.486, green: 0.227, blue: 0.929, alpha: 1) // #7C3AED
        case .rose: return NSColor(srgbRed: 0.882, green: 0.114, blue: 0.282, alpha: 1)   // #E11D48
        case .amber: return NSColor(srgbRed: 0.706, green: 0.325, blue: 0.035, alpha: 1)  // #B45309
        case .green: return NSColor(srgbRed: 0.082, green: 0.502, blue: 0.239, alpha: 1)  // #15803D
        case .teal: return NSColor(srgbRed: 0.059, green: 0.463, blue: 0.431, alpha: 1)   // #0F766E
        }
    }

    /// Fill role: primary buttons, switch tracks, selected swatch, stop button.
    var color: Color { Color(nsColor: nsColor) }

    /// Text and symbols placed on the fill.
    var onFill: Color {
        self == .system ? AppPalette.dynamic(light: 0xFFFFFF, dark: 0x1C1C1E) : .white
    }

    /// Foreground role: small selected icons and meter bars on app surfaces.
    var foreground: Color {
        if self == .system { return AppPalette.dynamic(light: 0x1C1C1E, dark: 0xECECEC) }
        let light = nsColor
        let dark = darkForeground
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }

    private var darkForeground: NSColor {
        switch self {
        case .system: return AppPalette.dynamicNS(light: 0xECECEC, dark: 0xECECEC)
        case .blue: return NSColor(srgbRed: 0.376, green: 0.647, blue: 0.980, alpha: 1)   // #60A5FA
        case .violet: return NSColor(srgbRed: 0.655, green: 0.545, blue: 0.980, alpha: 1) // #A78BFA
        case .rose: return NSColor(srgbRed: 0.984, green: 0.443, blue: 0.522, alpha: 1)   // #FB7185
        case .amber: return NSColor(srgbRed: 0.984, green: 0.749, blue: 0.141, alpha: 1)  // #FBBF24
        case .green: return NSColor(srgbRed: 0.290, green: 0.871, blue: 0.502, alpha: 1)  // #4ADE80
        case .teal: return NSColor(srgbRed: 0.176, green: 0.831, blue: 0.749, alpha: 1)   // #2DD4BF
        }
    }

    /// Tint for the few remaining system controls, such as progress spinners. Graphite keeps the system tint.
    var tint: Color? { self == .system ? nil : color }
}
