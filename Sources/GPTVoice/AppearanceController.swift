import AppKit
import Combine

/// Applies the saved theme to the whole app: windows, AppKit controls, and the overlay panel.
@MainActor
final class AppearanceController {
    private var themeObserver: AnyCancellable?

    init(preferences: AppPreferences) {
        NSApp.appearance = preferences.theme.appearance
        themeObserver = preferences.$theme
            .removeDuplicates()
            .sink { theme in NSApp.appearance = theme.appearance }
    }
}
