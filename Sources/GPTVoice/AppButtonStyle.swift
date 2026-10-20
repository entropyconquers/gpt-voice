import SwiftUI

/// Rounded-rectangle buttons (radius 10). Native `Button` semantics, keyboard activation, and focus stay intact.
struct AppButtonStyle: ButtonStyle {
    enum Kind {
        /// One per view. Accent fill.
        case primary
        /// Surface fill with a hairline.
        case secondary
        /// Text only until hovered.
        case quiet
        /// Problem-colored, for actions that stop or remove something.
        case destructive
    }

    var kind: Kind = .secondary
    var isLoading = false
    /// Adds a small plain arrow after the label, for navigation.
    var showsArrow = false
    var small = false
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        AppButtonLabel(configuration: configuration, style: self)
    }
}
