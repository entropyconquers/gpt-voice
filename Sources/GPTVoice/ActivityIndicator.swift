import SwiftUI

/// Small in-progress ring drawn in the secondary label color, so it reads on light and dark surfaces.
/// It spins only while shown. Under Reduce Motion it stays still, and the adjacent label carries the state.
struct ActivityIndicator: View {
    var size: CGFloat = 12
    @State private var spinning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(reduceMotion ? nil : .linear(duration: 0.9).repeatForever(autoreverses: false), value: spinning)
            .onAppear { spinning = !reduceMotion }
            .accessibilityHidden(true)
    }
}
