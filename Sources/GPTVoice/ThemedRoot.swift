import SwiftUI

/// Applies the saved accent and the default body font to a SwiftUI root, and updates both live.
/// Light and dark come from `NSApp.appearance`, set by `AppearanceController`.
struct ThemedRoot<Content: View>: View {
    @ObservedObject var preferences: AppPreferences
    let content: Content

    init(preferences: AppPreferences, @ViewBuilder content: () -> Content) {
        self.preferences = preferences
        self.content = content()
    }

    var body: some View {
        content
            .font(AppType.body)
            .environment(\.appAccent, preferences.accent.foreground)
            .environment(\.appAccentFill, preferences.accent.color)
            .environment(\.appAccentOnFill, preferences.accent.onFill)
            .tint(preferences.accent.tint)
    }
}
