// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GPTVoice",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "GPTVoice", targets: ["GPTVoice"])],
    targets: [
        .target(name: "DictationCore"),
        .executableTarget(name: "GPTVoice", dependencies: ["DictationCore"],
                          resources: [.copy("Resources/Fonts")]),
        .testTarget(name: "DictationCoreTests", dependencies: ["DictationCore"]),
        .testTarget(name: "DictationAppTests", dependencies: ["GPTVoice"])
    ]
)
