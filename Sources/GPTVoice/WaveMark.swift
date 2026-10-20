import SwiftUI

/// App mark: a graphite rounded square with five voice bars. Monochrome in both themes.
struct WaveMark: View {
    var size: CGFloat = 20

    private static let heights: [CGFloat] = [0.26, 0.5, 0.7, 0.44, 0.22]
    private static let ink = AppPalette.dynamic(light: 0x1C1C1E, dark: 0xECECEC)
    private static let paper = AppPalette.dynamic(light: 0xF4F4F3, dark: 0x1C1C1E)

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(Self.ink)
            .frame(width: size, height: size)
            .overlay(
                HStack(alignment: .center, spacing: size * 0.07) {
                    ForEach(Array(Self.heights.enumerated()), id: \.offset) { _, height in
                        Capsule()
                            .fill(Self.paper)
                            .frame(width: size * 0.08, height: size * height)
                    }
                }
            )
            .accessibilityHidden(true)
    }
}
