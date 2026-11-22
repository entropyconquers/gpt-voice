import AVFoundation
import XCTest
@testable import GPTVoice

final class RecordingCompressionTests: XCTestCase {
    func testUploadsSmallerAACAndRemovesItAfterAnUploadFailure() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let recording = directory.appendingPathComponent("recording.wav")
        try writeTestRecording(to: recording)
        let originalSize = try Data(contentsOf: recording).count
        var uploadCount = 0

        do {
            _ = try await RecordingCompression.transcribe(recording) { audio in
                uploadCount += 1
                XCTAssertEqual(audio.pathExtension, "m4a")
                let compressed = try AVAudioFile(forReading: audio)
                XCTAssertEqual(compressed.fileFormat.streamDescription.pointee.mFormatID, kAudioFormatMPEG4AAC)
                XCTAssertEqual(compressed.fileFormat.sampleRate, 24_000)
                XCTAssertEqual(compressed.fileFormat.channelCount, 1)
                XCTAssertEqual(compressed.length, 48_000)
                XCTAssertLessThan(try Data(contentsOf: audio).count, originalSize / 2)
                throw URLError(.timedOut)
            }
            XCTFail("Expected the upload error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        }

        XCTAssertEqual(uploadCount, 1)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["recording.wav"])
    }

    private func writeTestRecording(to url: URL) throws {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48_000))
        buffer.frameLength = 48_000
        let samples = try XCTUnwrap(buffer.floatChannelData)[0]
        for frame in 0..<Int(buffer.frameLength) {
            samples[frame] = Float(sin(2 * .pi * 440 * Double(frame) / format.sampleRate) * 0.25)
        }
        let output = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16
        ])
        try output.write(from: buffer)
    }
}
