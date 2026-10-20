import AppKit
import SwiftUI

/// Draws the system keyboard focus color around a custom-styled control while it has focus.
/// Custom button styles can lose the native ring, so this restores a visible 2 pt indicator.
struct KeyboardFocusRing<RingShape: InsettableShape>: ViewModifier {
    let isFocused: Bool
    let shape: RingShape

    func body(content: Content) -> some View {
        content.overlay(
            shape
                .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                .opacity(isFocused ? 1 : 0)
                .allowsHitTesting(false)
        )
    }
}
