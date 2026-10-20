import Carbon.HIToolbox
import Foundation

/// Registers one global hotkey with Carbon `RegisterEventHotKey`.
/// No event tap is used, so Input Monitoring permission is not needed.
@MainActor
final class GlobalShortcut {
    enum RegistrationError: LocalizedError, Equatable {
        case invalid(HotkeySpec.Problem)
        case conflict
        case systemShortcut(HotkeySpec)
        case system(OSStatus)

        var errorDescription: String? {
            switch self {
            case .invalid(let problem): return problem.message
            case .conflict: return "Another app uses this shortcut. Choose another one."
            case .systemShortcut(let spec):
                return spec == .commandSpace
                    ? "Spotlight uses Command–Space. Turn off or change that shortcut in System Settings → Keyboard → Keyboard Shortcuts → Spotlight, then try again."
                    : "macOS uses this shortcut. Change it in System Settings → Keyboard → Keyboard Shortcuts, then try again."
            case .system(let status): return "macOS could not register this shortcut (error \(status))."
            }
        }
    }

    private static let signature: OSType = 0x4344_6374 // "CDct"

    private(set) var current: HotkeySpec?
    private var currentRef: EventHotKeyRef?
    private var currentID: UInt32 = 0
    private var nextID: UInt32 = 1
    private var handlerRef: EventHandlerRef?
    private let onPress: @MainActor () -> Void

    init(onPress: @escaping @MainActor () -> Void) {
        self.onPress = onPress
        installHandler()
    }

    deinit {
        if let currentRef { UnregisterEventHotKey(currentRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    /// Registers `spec` as the active shortcut. The previous shortcut stays
    /// active when the new registration fails.
    func replace(with spec: HotkeySpec) throws {
        if let problem = spec.problem { throw RegistrationError.invalid(problem) }
        if Self.isSystemShortcutEnabled(spec) { throw RegistrationError.systemShortcut(spec) }
        if spec == current, currentRef != nil { return }

        let previousRef = currentRef
        // The same combination cannot register twice. Release it first, and put it back on failure.
        let sameCombination = previousRef != nil && current.map {
            $0.keyCode == spec.keyCode && $0.modifiers == spec.modifiers
        } == true
        if sameCombination, let previousRef {
            UnregisterEventHotKey(previousRef)
            currentRef = nil
        }

        let id = nextID
        nextID &+= 1
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(spec.keyCode, spec.modifiers,
                                         EventHotKeyID(signature: Self.signature, id: id),
                                         GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &ref)
        guard status == noErr, let ref else {
            if sameCombination, let old = current { restore(old) }
            throw status == OSStatus(eventHotKeyExistsErr) ? RegistrationError.conflict : RegistrationError.system(status)
        }
        if !sameCombination, let previousRef { UnregisterEventHotKey(previousRef) }
        currentRef = ref
        currentID = id
        current = spec
    }

    /// Removes the active shortcut.
    func unregister() {
        if let currentRef { UnregisterEventHotKey(currentRef) }
        currentRef = nil
        current = nil
    }

    private func restore(_ spec: HotkeySpec) {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(spec.keyCode, spec.modifiers,
                                         EventHotKeyID(signature: Self.signature, id: currentID),
                                         GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &ref)
        if status == noErr { currentRef = ref } else { current = nil }
    }

    fileprivate func handlePress(id: UInt32) {
        guard id == currentID, currentRef != nil else { return }
        onPress()
    }

    static func isSystemShortcutEnabled(_ spec: HotkeySpec) -> Bool {
        var shortcuts: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&shortcuts) == noErr,
              let entries = shortcuts?.takeRetainedValue() as? [[String: Any]] else { return false }
        return entries.contains { entry in
            guard (entry[kHISymbolicHotKeyEnabled] as? NSNumber)?.boolValue == true,
                  let code = entry[kHISymbolicHotKeyCode] as? NSNumber,
                  let modifiers = entry[kHISymbolicHotKeyModifiers] as? NSNumber else { return false }
            return HotkeySpec(keyCode: code.uint32Value, modifiers: modifiers.uint32Value) == spec
        }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            guard status == noErr, hotKeyID.signature == GlobalShortcut.signature else {
                return OSStatus(eventNotHandledErr)
            }
            let shortcut = Unmanaged<GlobalShortcut>.fromOpaque(userData).takeUnretainedValue()
            let id = hotKeyID.id
            DispatchQueue.main.async { shortcut.handlePress(id: id) }
            return noErr
        }, 1, &eventType, context, &handlerRef)
    }
}
