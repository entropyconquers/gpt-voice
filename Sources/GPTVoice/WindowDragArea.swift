import SwiftUI

/// SwiftUI wrapper for a draggable blank header region. Place it only where no control sits.
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragView { WindowDragView() }
    func updateNSView(_ view: WindowDragView, context: Context) {}
}
