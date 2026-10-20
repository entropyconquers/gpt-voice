import SwiftUI

/// Five bars driven only by the real input level. Silence shows flat bars.
struct LevelMeterView: View {
    let level: Float
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Fixed shape so louder input reads taller in the middle. Not animated on its own.
    private static let weights: [CGFloat] = [0.55, 0.8, 1, 0.8, 0.55]
    private static let barWidth: CGFloat = 3
    private static let minimumHeight: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(Self.weights.enumerated()), id: \.offset) { _, weight in
                    Capsule()
                        .fill(accent)
                        .frame(width: Self.barWidth,
                               height: max(Self.minimumHeight, proxy.size.height * weight * CGFloat(level)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : .linear(duration: 0.08), value: level)
        }
        .accessibilityElement()
        .accessibilityLabel("Input level")
        .accessibilityValue("\(Int(level * 100)) percent")
    }
}
