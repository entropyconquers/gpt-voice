import SwiftUI

/// Flat, near-opaque overlay surface with a hairline border. Stronger under Increase Contrast.
struct OverlaySurface<SurfaceShape: InsettableShape>: ViewModifier {
    let shape: SurfaceShape
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let increased = contrast == .increased
        content
            .background(shape.fill(AppPalette.surface.opacity(increased ? 1 : 0.97)))
            .overlay(shape.strokeBorder(Color.primary.opacity(increased ? 0.5 : 0.12), lineWidth: increased ? 1.5 : 1))
            .clipShape(shape)
    }
}
