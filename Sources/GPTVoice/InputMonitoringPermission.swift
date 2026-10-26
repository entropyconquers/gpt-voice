import CoreGraphics

/// Input Monitoring is required to observe a modifier key pressed by itself.
/// Carbon hotkeys do not need it, and this type does not prompt on its own.
enum InputMonitoringPermission {
    static var isGranted: Bool { CGPreflightListenEventAccess() }

    /// Shows the system prompt when access is missing. Returns the resulting grant.
    static func request() -> Bool { CGRequestListenEventAccess() }
}
