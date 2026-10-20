import AppKit
import ApplicationServices

/// The app and, when Accessibility allows it, the focused element and window at recording start.
struct PasteTarget {
    let processID: pid_t
    let appName: String?
    let focusedElement: AXUIElement?
    let focusedWindow: AXUIElement?

    /// Captures the frontmost app. Returns nil when this app is frontmost.
    static func captureFrontmost() -> PasteTarget? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        let pid = app.processIdentifier
        let focus: (element: AXUIElement?, window: AXUIElement?) =
            AccessibilityPermission.check() ? focusedAttributes(of: pid) : (element: nil, window: nil)
        return PasteTarget(processID: pid, appName: app.localizedName,
                           focusedElement: focus.element, focusedWindow: focus.window)
    }

    /// True when the same process is frontmost and any captured focus still matches.
    func isStillFrontmost() -> Bool {
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == processID else { return false }
        guard focusedElement != nil || focusedWindow != nil else { return true }
        let now = Self.focusedAttributes(of: processID)
        if let focusedWindow {
            guard let window = now.window, CFEqual(focusedWindow, window) else { return false }
        }
        if let focusedElement {
            guard let element = now.element, CFEqual(focusedElement, element) else { return false }
        }
        return true
    }

    private static func focusedAttributes(of pid: pid_t) -> (element: AXUIElement?, window: AXUIElement?) {
        let app = AXUIElementCreateApplication(pid)
        return (copyElement(app, kAXFocusedUIElementAttribute), copyElement(app, kAXFocusedWindowAttribute))
    }

    private static func copyElement(_ owner: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(owner, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}
