import Foundation

/// User preferences. Stores only settings and onboarding state.
/// Never stores credentials, audio, or transcripts.
@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let hotkey = "hotkey"
        static let automaticPaste = "automaticPaste"
        static let soundCues = "soundCues"
        static let onboardingCompleted = "onboardingCompleted"
        static let theme = "theme"
        static let accent = "accent"
        static let overlayPlacement = "overlayPlacement"
        static let manualPasteHelpDismissed = "manualPasteHelpDismissed"
    }

    @Published var overlayPlacement: OverlayPlacement {
        didSet { defaults.set(overlayPlacement.rawValue, forKey: Key.overlayPlacement) }
    }

    @Published var manualPasteHelpDismissed: Bool {
        didSet { defaults.set(manualPasteHelpDismissed, forKey: Key.manualPasteHelpDismissed) }
    }

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    @Published var accent: AccentChoice {
        didSet { defaults.set(accent.rawValue, forKey: Key.accent) }
    }

    private let defaults: UserDefaults

    @Published var hotkey: HotkeySpec {
        didSet {
            guard let data = try? JSONEncoder().encode(hotkey) else { return }
            defaults.set(data, forKey: Key.hotkey)
        }
    }

    @Published var automaticPaste: Bool {
        didSet { defaults.set(automaticPaste, forKey: Key.automaticPaste) }
    }

    @Published var soundCues: Bool {
        didSet { defaults.set(soundCues, forKey: Key.soundCues) }
    }

    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.automaticPaste: true,
            Key.soundCues: false,
            Key.onboardingCompleted: false
        ])
        let stored = defaults.data(forKey: Key.hotkey).flatMap { try? JSONDecoder().decode(HotkeySpec.self, from: $0) }
        hotkey = stored.flatMap { $0.isValid ? $0 : nil } ?? .default
        automaticPaste = defaults.bool(forKey: Key.automaticPaste)
        soundCues = defaults.bool(forKey: Key.soundCues)
        onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
        theme = defaults.string(forKey: Key.theme).flatMap(AppTheme.init(rawValue:)) ?? .system
        accent = defaults.string(forKey: Key.accent).flatMap(AccentChoice.init(rawValue:)) ?? .system
        overlayPlacement = defaults.string(forKey: Key.overlayPlacement)
            .flatMap(OverlayPlacement.init(rawValue:)) ?? .bottom
        manualPasteHelpDismissed = defaults.bool(forKey: Key.manualPasteHelpDismissed)
    }
}
