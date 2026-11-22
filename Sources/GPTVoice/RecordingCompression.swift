import AVFoundation
import Foundation

enum RecordingCompression {
    /// Uses the original recording if local encoding fails. The caller keeps ownership of it for Retry.
    static func transcribe(_ recording: URL, using upload: (URL) async throws -> String) async throws -> String {
        let compressed = recording.deletingLastPathComponent().appendingPathComponent("\(UUID().uuidString).m4a")
        defer { try? FileManager.default.removeItem(at: compressed) }

        let audioToUpload: URL
        do {
            try encode(recording, to: compressed)
            audioToUpload = compressed
        } catch {
            audioToUpload = recording
        }
        try Task.checkCancellation()
        return try await upload(audioToUpload)
    }

    private static func encode(_ recording: URL, to compressed: URL) throws {
        let input = try AVAudioFile(forReading: recording)
        let format = input.processingFormat
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderBitRateKey: 48_000
        ]
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8192) else {
            throw CocoaError(.fileReadUnknown)
        }
        let output = try AVAudioFile(forWriting: compressed, settings: settings,
                                     commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        let frameCount = input.length
        while input.framePosition < frameCount {
            try Task.checkCancellation()
            try input.read(into: buffer)
            guard buffer.frameLength > 0 else { throw CocoaError(.fileReadCorruptFile) }
            try output.write(from: buffer)
        }
    }
}
