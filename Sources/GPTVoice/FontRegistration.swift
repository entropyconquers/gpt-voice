import AppKit
import CoreText
import Foundation

enum FontRegistration {
    static var fontAvailability: [String: Bool] {
        ["FTRegolaNeue-Regular", "FTRegolaNeue-Medium", "FTRegolaNeue-Semibold"].reduce(into: [:]) { result, name in
            result[name] = NSFont(name: name, size: 16)?.fontName == name
        }
    }

    static func registerBundledFonts() {
        // SwiftPM's generated accessor searches beside the executable. App bundles keep resources
        // in Contents/Resources, so resolve that location before the development-build fallback.
        let resources: URL?
        if Bundle.main.bundleURL.pathExtension == "app" {
            resources = Bundle.main.url(forResource: "GPTVoice_GPTVoice", withExtension: "bundle")
                .flatMap { Bundle(url: $0)?.resourceURL }
        } else {
            resources = Bundle.module.resourceURL
        }
        guard let root = resources?.appendingPathComponent("Fonts"),
              let files = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return }
        for file in files where ["ttf", "otf"].contains(file.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
        }
    }
}
