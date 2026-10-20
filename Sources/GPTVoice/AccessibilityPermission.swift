import AppKit
import ApplicationServices

enum AccessibilityPermission {
    /// Checks a real, read-only AX request when the trust flag has not refreshed yet.
    /// No text, window titles, or focused content is read.
    static func check() -> Bool {
        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return AXIsProcessTrustedWithOptions(nil)
        }
        let application = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.2)
        var role: CFTypeRef?
        switch AXUIElementCopyAttributeValue(application, kAXRoleAttribute as CFString, &role) {
        case .success: return true
        case .apiDisabled: return false
        default: return AXIsProcessTrustedWithOptions(nil)
        }
    }
}
