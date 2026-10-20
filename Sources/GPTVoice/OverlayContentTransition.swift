import SwiftUI

struct OverlayContentTransition: AnimatableModifier {
    var opacity: Double
    var blur: CGFloat

    var animatableData: AnimatablePair<Double, CGFloat> {
        get { AnimatablePair(opacity, blur) }
        set { opacity = newValue.first; blur = newValue.second }
    }

    func body(content: Content) -> some View {
        content.opacity(opacity).blur(radius: blur)
    }

    static func transition(reduceMotion: Bool) -> AnyTransition {
        .modifier(active: Self(opacity: 0, blur: reduceMotion ? 0 : 2.5),
                  identity: Self(opacity: 1, blur: 0))
    }
}
