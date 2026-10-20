import AppKit
import SwiftUI

/// Settings window: sidebar and one scrollable page under integrated window chrome.
struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences
    @State private var page: SettingsPage = .home
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel) {
        self.model = model
        self.preferences = model.preferences
    }

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $page)
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeader(title: page.title, intro: page.intro)
                        if !model.canChangeSettings, page != .appearance {
                            SettingsLockBanner()
                        }
                        content
                            .id(page)
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, HostingWindowController.chromeHeight)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                // Blank header strip: drags the window. Content scrolls under a short fade.
                WindowDragArea()
                    .frame(height: HostingWindowController.chromeHeight - 12)
                    .background(LinearGradient(colors: [AppPalette.canvas, AppPalette.canvas.opacity(0)],
                                               startPoint: .top, endPoint: .bottom))
            }
            .background(AppPalette.canvas)
        }
        .animation(AppMotion.reveal(reduceMotion), value: page)
        .frame(minWidth: 720, idealWidth: 820, minHeight: 540, idealHeight: 600)
        .onAppear { model.refreshStatus() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            model.refreshStatus()
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .home: HomePage(model: model) { page = $0 }
        case .shortcuts: ShortcutPanel(model: model)
        case .appearance: AppearanceSection(preferences: preferences)
        case .preferences: BehaviorSection(model: model)
        case .privacy: PrivacyPage(model: model)
        }
    }
}
