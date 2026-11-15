import Foundation

/// The loading indicator and important error/copy instructions always remain
/// visible. Recording keeps at least one indicator even if every option is off.
struct PillContents: Codable, Equatable {
    var waveform = true
    var timer = true
    var recordingDot = true
    var cancelButton = true
    var stopButton = true
    var statusText = true

    static let standard = PillContents()
    static let minimal = PillContents(waveform: true, timer: false, recordingDot: false,
                                     cancelButton: false, stopButton: false, statusText: false)
    var showsWaveform: Bool { waveform || (!timer && !recordingDot) }
}
