import AppKit

/// Holds one modifier key to record, then releases it to finish.
/// The event is never swallowed, so a chord still reaches the frontmost app.
final class ModifierHoldListener {
    private var tracker: ModifierHoldTracker
    private let onBegan: @MainActor () -> Void
    private let onEnded: @MainActor () -> Void
    private let onCancelled: @MainActor () -> Void
    private var monitors: [Any] = []
    /// Last device-dependent modifier bits. `flagsChanged` key codes are not reliable.
    private var deviceFlags: UInt = 0
    private var armToken = 0

    init(keyCode: UInt32, onBegan: @escaping @MainActor () -> Void, onEnded: @escaping @MainActor () -> Void,
         onCancelled: @escaping @MainActor () -> Void) {
        tracker = ModifierHoldTracker(keyCode: keyCode)
        self.onBegan = onBegan
        self.onEnded = onEnded
        self.onCancelled = onCancelled
    }

    deinit { stop() }

    /// Installs the monitors. Returns false when macOS will not deliver global key events.
    func start() -> Bool {
        stop()
        let mask: NSEvent.EventTypeMask = [
            .flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel
        ]
        guard let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
        }) else { return false }
        monitors.append(global)
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
            return event
        }) {
            monitors.append(local)
        }
        return true
    }

    func stop() {
        armToken += 1
        for monitor in monitors { NSEvent.removeMonitor(monitor) }
        monitors.removeAll()
        tracker.reset()
        deviceFlags = 0
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            perform(consumeFlags(event))
        case .keyDown:
            perform(tracker.chordFromKey())
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel:
            perform(tracker.pointer())
        default:
            return
        }
    }

    /// Uses the changed device-dependent bit, not `NSEvent.keyCode`.
    private func consumeFlags(_ event: NSEvent) -> ModifierHoldTracker.Action {
        let raw = UInt(event.modifierFlags.rawValue)
        let current = raw & HotkeySpec.deviceModifierMasks
        let changed = deviceFlags ^ current
        deviceFlags = current
        let watched = tracker.keyCode
        if changed == 0 {
            return tracker.consume(eventKeyCode: nil, modifierDown: false, otherModifierDown: false, cancelsHold: false)
        }
        if changed & (changed - 1) != 0 {
            return tracker.consume(eventKeyCode: nil, modifierDown: false, otherModifierDown: true, cancelsHold: false)
        }
        let code = HotkeySpec.keyCode(forDeviceMask: changed)
        let down = current & changed != 0
        return tracker.consume(
            eventKeyCode: code,
            modifierDown: down && code == watched,
            otherModifierDown: HotkeySpec.hasOtherDeviceModifier(than: watched, rawFlags: raw),
            cancelsHold: false)
    }

    private func perform(_ action: ModifierHoldTracker.Action) {
        switch action {
        case .none:
            break
        case .arm:
            armToken += 1
            let token = armToken
            DispatchQueue.main.asyncAfter(deadline: .now() + ModifierHoldTracker.minimumHold) { [weak self] in
                guard let self, self.armToken == token, self.tracker.commit() else { return }
                self.deliver(self.onBegan)
            }
        case .disarm:
            armToken += 1
        case .end:
            armToken += 1
            deliver(onEnded)
        case .cancelSession:
            armToken += 1
            deliver(onCancelled)
        }
    }

    private func deliver(_ callback: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async {
            callback()
        }
    }
}
