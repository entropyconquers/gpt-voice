import AppKit
import SwiftUI

/// Version and documentation link, shown at the bottom of Privacy.
struct AboutSection: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        guard let short = info?["CFBundleShortVersionString"] as? String else { return "Development build" }
        return "Version \(short)"
    }

    var body: some View {
        HStack(spacing: 10) {
            WaveMark(size: 18)
            Text("GPT Voice").font(AppType.brand)
            Text(version).font(AppType.detail).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Button("Codex CLI documentation") { NSWorkspace.shared.open(AppModel.installCodexURL) }
                .buttonStyle(AppButtonStyle(kind: .quiet, showsArrow: true, small: true))
        }
    }
}
