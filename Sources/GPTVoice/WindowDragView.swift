import AppKit

/// Blank header area that moves the window. A double-click follows the system title-bar action.
final class WindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") ?? "Maximize"
            if action == "Minimize" {
                window?.performMiniaturize(nil)
            } else if action != "None" {
                window?.performZoom(nil)
            }
            return
        }
        window?.performDrag(with: event)
    }
}
