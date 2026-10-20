import AppKit

enum SoundCue {
    case start
    case stop
    case failure

    func play() {
        let name: String
        switch self {
        case .start: name = "Tink"
        case .stop: name = "Pop"
        case .failure: name = "Basso"
        }
        NSSound(named: NSSound.Name(name))?.play()
    }
}
