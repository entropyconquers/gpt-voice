import AppKit
import Carbon.HIToolbox

/// A global keyboard shortcut: one virtual key code plus Carbon modifier flags.
struct HotkeySpec: Codable, Equatable, Hashable {
    enum Problem: Equatable {
        case needsModifier
        case modifierOnly
        case reserved

        var message: String {
            switch self {
            case .needsModifier: return "Use Control, Option, or Command with a key."
            case .modifierOnly: return "Add a key to the modifiers."
            case .reserved: return "macOS uses this shortcut. Choose another one."
            }
        }
    }

    let keyCode: UInt32
    let modifiers: UInt32

    static let `default` = HotkeySpec(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey))
    static let commandSpace = HotkeySpec(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey))

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers & Self.supportedModifiers
    }

    /// Builds a shortcut from an AppKit key event's code and modifier flags.
    init(keyCode: UInt16, cocoaModifiers flags: NSEvent.ModifierFlags) {
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        self.init(keyCode: UInt32(keyCode), modifiers: carbon)
    }

    private static let supportedModifiers = UInt32(controlKey | optionKey | shiftKey | cmdKey)
    private static let primaryModifiers = UInt32(controlKey | optionKey | cmdKey)

    private static let modifierKeyCodes: Set<UInt32> = [
        kVK_Command, kVK_RightCommand, kVK_Shift, kVK_RightShift, kVK_Option, kVK_RightOption,
        kVK_Control, kVK_RightControl, kVK_CapsLock, kVK_Function
    ].reduce(into: []) { $0.insert(UInt32($1)) }

    private static let reservedShortcuts: Set<HotkeySpec> = [
        HotkeySpec(keyCode: UInt32(kVK_Tab), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_Tab), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_Grave), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_W), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_M), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_X), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_Z), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_A), modifiers: UInt32(cmdKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey | controlKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeySpec(keyCode: UInt32(kVK_ANSI_F), modifiers: UInt32(cmdKey | controlKey)),
        HotkeySpec(keyCode: UInt32(kVK_Escape), modifiers: UInt32(cmdKey | optionKey))
    ]

    /// The first reason this shortcut cannot be used, or nil when it is acceptable.
    var problem: Problem? {
        if Self.modifierKeyCodes.contains(keyCode) { return .modifierOnly }
        if modifiers & Self.primaryModifiers == 0 { return .needsModifier }
        if Self.reservedShortcuts.contains(self) { return .reserved }
        return nil
    }

    var isValid: Bool { problem == nil }

    /// Modifier symbols in macOS order, then the key name. For keycap display.
    var keycaps: [String] {
        var caps: [String] = []
        if modifiers & UInt32(controlKey) != 0 { caps.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { caps.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { caps.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { caps.append("⌘") }
        caps.append(keyName)
        return caps
    }

    /// Compact label, for example "⌃⌥Space".
    var displayLabel: String { keycaps.joined() }

    /// Spoken label for VoiceOver, for example "Control Option Space".
    var accessibilityLabel: String {
        var words: [String] = []
        if modifiers & UInt32(controlKey) != 0 { words.append("Control") }
        if modifiers & UInt32(optionKey) != 0 { words.append("Option") }
        if modifiers & UInt32(shiftKey) != 0 { words.append("Shift") }
        if modifiers & UInt32(cmdKey) != 0 { words.append("Command") }
        words.append(keyName)
        return words.joined(separator: " ")
    }

    /// AppKit modifier flags, for menu item shortcut hints.
    var cocoaModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if modifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if modifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if modifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        return flags
    }

    /// A menu key equivalent string, or nil when the key has no single-character form.
    var menuKeyEquivalent: String? {
        if Int(keyCode) == kVK_Space { return " " }
        let name = keyName
        return name.count == 1 && name.allSatisfy(\.isASCII) ? name.lowercased() : nil
    }

    var keyName: String {
        Self.keyNames[Int(keyCode)] ?? "Key \(keyCode)"
    }

    private static let keyNames: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "Return", kVK_Tab: "Tab", kVK_Delete: "Delete",
        kVK_ForwardDelete: "Forward Delete", kVK_Escape: "Esc",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "Home", kVK_End: "End", kVK_PageUp: "Page Up", kVK_PageDown: "Page Down",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17",
        kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D", kVK_ANSI_E: "E",
        kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H", kVK_ANSI_I: "I", kVK_ANSI_J: "J",
        kVK_ANSI_K: "K", kVK_ANSI_L: "L", kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O",
        kVK_ANSI_P: "P", kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X", kVK_ANSI_Y: "Y",
        kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4",
        kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=", kVK_ANSI_LeftBracket: "[",
        kVK_ANSI_RightBracket: "]", kVK_ANSI_Backslash: "\\", kVK_ANSI_Semicolon: ";",
        kVK_ANSI_Quote: "'", kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".", kVK_ANSI_Slash: "/",
        kVK_ANSI_Grave: "`"
    ]
}
