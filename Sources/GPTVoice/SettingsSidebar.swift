import SwiftUI

/// Settings navigation. The top strip stays clear for the native window buttons and drags the window.
struct SettingsSidebar: View {
    @Binding var selection: SettingsPage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            WindowDragArea()
                .frame(height: HostingWindowController.chromeHeight)

            HStack(spacing: 8) {
                WaveMark(size: 20)
                Text("GPT Voice").font(AppType.heading)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("GPT Voice")

            ForEach(SettingsPage.allCases) { page in
                Button(page.title) { selection = page }
                    .buttonStyle(SidebarButtonStyle(isSelected: page == selection, symbol: page.symbol))
                    .accessibilityAddTraits(page == selection ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 16)
        .frame(width: 192)
        .frame(maxHeight: .infinity)
        .background(AppPalette.sidebar)
        .overlay(alignment: .trailing) { Rectangle().fill(AppPalette.hairline).frame(width: 1) }
    }
}
