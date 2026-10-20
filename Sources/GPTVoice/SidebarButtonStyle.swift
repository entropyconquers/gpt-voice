import SwiftUI

/// Sidebar row: plain icon and text, quiet selection fill, hover tint, and a keyboard focus ring.
struct SidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    let symbol: String

    func makeBody(configuration: Configuration) -> some View {
        SidebarItemLabel(configuration: configuration, isSelected: isSelected, symbol: symbol)
    }
}
