import Combine

@MainActor
final class OverlayPresentation: ObservableObject {
    @Published var state: DictationOverlayState = .hidden
    @Published var exiting = false
}
