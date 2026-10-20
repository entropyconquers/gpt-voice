import AVFoundation
import Foundation

/// Records mono 24 kHz 16-bit PCM WAV files into a private temporary directory.
/// Recording starts only from an explicit `start()` call.
@MainActor
final class AudioCapture: NSObject, AVAudioRecorderDelegate {
    static let maximumDuration: TimeInterval = 300

    /// Called when the 5-minute cap ends the recording. The file is complete and owned by the caller.
    var onMaximumDuration: ((URL) -> Void)?
    /// Called when the device or encoder fails. The partial file is kept for Retry when it exists.
    var onFailure: ((AudioCaptureError, URL?) -> Void)?

    private var recorder: AVAudioRecorder?
    private var directory: URL?
    private var ownedFiles: Set<URL> = []
    private var generation = 0
    private var stoppingByRequest = false

    static var microphoneStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    var isRecording: Bool { recorder != nil }

    /// Seconds recorded so far, or zero when idle.
    var elapsed: TimeInterval { recorder?.currentTime ?? 0 }

    /// Normalized input level from 0 to 1, or zero when idle. For UI only.
    func currentLevel() -> Float {
        guard let recorder else { return 0 }
        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0)
        return max(0, min(1, (decibels + 50) / 50))
    }

    /// Asks for microphone access on first use, then starts recording.
    func start() async throws {
        guard recorder == nil else { throw AudioCaptureError.alreadyRecording }
        generation += 1
        let startGeneration = generation
        switch Self.microphoneStatus {
        case .authorized: break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard granted else { throw AudioCaptureError.microphoneDenied }
        default: throw AudioCaptureError.microphoneDenied
        }
        guard startGeneration == generation, recorder == nil else { throw AudioCaptureError.cancelled }

        let url = try makeFileURL()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 24_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        let newRecorder: AVAudioRecorder
        do {
            newRecorder = try AVAudioRecorder(url: url, settings: settings)
        } catch {
            throw AudioCaptureError.startFailed
        }
        newRecorder.delegate = self
        newRecorder.isMeteringEnabled = true
        ownedFiles.insert(url)
        guard newRecorder.prepareToRecord(), newRecorder.record(forDuration: Self.maximumDuration) else {
            remove(url)
            throw AudioCaptureError.startFailed
        }
        stoppingByRequest = false
        recorder = newRecorder
    }

    /// Stops recording and returns the finished file. The caller removes it with `remove(_:)`.
    func stop() throws -> URL {
        guard let recorder else { throw AudioCaptureError.notRecording }
        stoppingByRequest = true
        recorder.stop()
        self.recorder = nil
        generation += 1
        return recorder.url
    }

    /// Stops any recording, including a pending permission request, and deletes its file.
    func cancel() {
        generation += 1
        guard let recorder else { return }
        stoppingByRequest = true
        recorder.stop()
        self.recorder = nil
        remove(recorder.url)
    }

    /// Deletes one owned audio file, for example after a successful transcription.
    func remove(_ url: URL) {
        guard ownedFiles.remove(url) != nil else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Cancels recording and deletes every owned file and the private directory. Call on quit.
    func cleanup() {
        cancel()
        for url in ownedFiles { try? FileManager.default.removeItem(at: url) }
        ownedFiles.removeAll()
        if let directory { try? FileManager.default.removeItem(at: directory) }
        directory = nil
    }

    private func makeFileURL() throws -> URL {
        if directory == nil {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("GPTVoice-\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false,
                                                        attributes: [.posixPermissions: 0o700])
            } catch {
                throw AudioCaptureError.startFailed
            }
            directory = url
        }
        return directory!.appendingPathComponent("\(UUID().uuidString).wav")
    }

    private func recorderFinished(_ finished: AVAudioRecorder, successfully: Bool) {
        guard finished === recorder, !stoppingByRequest else { return }
        recorder = nil
        generation += 1
        let url = finished.url
        if successfully {
            onMaximumDuration?(url)
        } else {
            onFailure?(.deviceFailed, ownedFiles.contains(url) ? url : nil)
        }
    }

    private func recorderFailed(_ failed: AVAudioRecorder) {
        guard failed === recorder else { return }
        stoppingByRequest = true
        failed.stop()
        recorder = nil
        generation += 1
        onFailure?(.deviceFailed, ownedFiles.contains(failed.url) ? failed.url : nil)
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { self.recorderFinished(recorder, successfully: flag) }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async { self.recorderFailed(recorder) }
    }
}
