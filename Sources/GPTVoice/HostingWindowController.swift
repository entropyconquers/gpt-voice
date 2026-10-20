import AppKit
import SwiftUI

/// A window that hosts one SwiftUI view with integrated chrome: content runs under a hidden, transparent
/// title bar, and the real traffic-light buttons sit at the top left of the custom header.
/// Showing it activates the app because the user asked for it.
@MainActor
final class HostingWindowController: NSWindowController, NSWindowDelegate {
    /// Height of the header strip that holds the traffic lights. Views keep this area free of controls.
    static let chromeHeight: CGFloat = 52

    private let onClose: () -> Void

    init<Content: View>(title: String, size: NSSize, minSize: NSSize = NSSize(width: 640, height: 520),
                        rootView: Content, onClose: @escaping () -> Void) {
        self.onClose = onClose
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        // The title stays set for the Window menu, Mission Control, and VoiceOver. It is not drawn.
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.toolbar = nil
        window.isMovableByWindowBackground = false
        window.backgroundColor = AppPalette.nsCanvas
        window.isReleasedWhenClosed = false
        // Open on the user's current desktop instead of switching to the Space where it was last shown.
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.contentMinSize = minSize
        let hosting = NSHostingController(rootView: rootView.ignoresSafeArea())
        window.contentViewController = hosting
        window.setContentSize(size)
        window.center()
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { nil }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Ends a shortcut capture so the saved shortcut is registered again.
        window?.makeFirstResponder(nil)
        onClose()
    }
}
