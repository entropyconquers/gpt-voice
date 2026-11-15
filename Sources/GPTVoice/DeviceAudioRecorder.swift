import AudioToolbox
import Foundation

/// A device-specific input queue. The system-default path continues to use
/// AVAudioRecorder. All file writes run on one serial callback queue.
final class DeviceAudioRecorder: @unchecked Sendable {
    var onFailure: (() -> Void)?
    var onMaximumDuration: (() -> Void)?
    private let callbacks = DispatchQueue(label: "GPTVoice.device-audio")
    private let writer: PCMRecordingFile
    private let deviceUID: String
    private var queue: AudioQueueRef?
    private var stopping = false
    private var reportedEnd = false
    private var started = false

    init(url: URL, deviceUID: String) throws {
        self.deviceUID = deviceUID
        writer = try PCMRecordingFile(url: url)
        var format = PCMRecordingFile.format
        let status = AudioQueueNewInputWithDispatchQueue(&queue, &format, 0, callbacks) { [weak self] queue, buffer, _, _, _ in
            self?.consume(queue: queue, buffer: buffer)
        }
        guard status == noErr, let queue else { stop(); throw AudioCaptureError.startFailed }
        var uid = deviceUID as CFString
        let selected = withUnsafePointer(to: &uid) {
            AudioQueueSetProperty(queue, kAudioQueueProperty_CurrentDevice, UnsafeRawPointer($0),
                                  UInt32(MemoryLayout<CFString>.size))
        }
        guard selected == noErr else {
            stop(); throw AudioCaptureError.startFailed
        }
        var metering: UInt32 = 1
        AudioQueueSetProperty(queue, kAudioQueueProperty_EnableLevelMetering, &metering, UInt32(MemoryLayout<UInt32>.size))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let listenerStatus = AudioQueueAddPropertyListener(queue, kAudioQueueProperty_IsRunning, { context, queue, _ in
            guard let context else { return }
            let recorder = Unmanaged<DeviceAudioRecorder>.fromOpaque(context).takeUnretainedValue()
            recorder.callbacks.async { [weak recorder] in recorder?.checkRunning(queue) }
        }, context)
        guard listenerStatus == noErr else { stop(); throw AudioCaptureError.startFailed }
        for _ in 0..<3 {
            var buffer: AudioQueueBufferRef?
            // 20 ms of mono PCM per buffer; conversion is handled by Audio Queue.
            guard AudioQueueAllocateBuffer(queue, 960, &buffer) == noErr, let buffer,
                  AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == noErr else {
                stop(); throw AudioCaptureError.startFailed
            }
        }
    }

    func start() throws {
        guard let queue else { throw AudioCaptureError.startFailed }
        callbacks.sync { started = true }
        guard AudioQueueStart(queue, nil) == noErr, currentDeviceUID == deviceUID else {
            stop(); throw AudioCaptureError.startFailed
        }
    }

    var currentDeviceUID: String? {
        guard let queue else { return nil }
        var uid: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = withUnsafeMutablePointer(to: &uid) {
            AudioQueueGetProperty(queue, kAudioQueueProperty_CurrentDevice, UnsafeMutableRawPointer($0), &size)
        }
        return status == noErr ? uid as String : nil
    }

    var elapsed: TimeInterval { callbacks.sync { Double(writer.frames) / 24_000 } }

    func level() -> Float {
        guard let queue else { return 0 }
        var meter = AudioQueueLevelMeterState(mAveragePower: -50, mPeakPower: -50)
        var size = UInt32(MemoryLayout<AudioQueueLevelMeterState>.size)
        guard AudioQueueGetProperty(queue, kAudioQueueProperty_CurrentLevelMeterDB, &meter, &size) == noErr else { return 0 }
        return max(0, min(1, (meter.mAveragePower + 50) / 50))
    }

    /// Disposes callbacks synchronously before closing the WAV header.
    func stop() {
        guard let queue else { writer.close(); return }
        callbacks.sync { stopping = true }
        AudioQueueStop(queue, true)
        AudioQueueDispose(queue, true)
        self.queue = nil
        callbacks.sync { writer.close() }
    }

    deinit { stop() }

    private func consume(queue: AudioQueueRef, buffer: AudioQueueBufferRef) {
        guard !reportedEnd else { return }
        do {
            try writer.write(buffer.pointee.mAudioData, byteCount: buffer.pointee.mAudioDataByteSize)
            if writer.reachedLimit {
                reportedEnd = true
                DispatchQueue.main.async { [weak self] in self?.onMaximumDuration?() }
            } else if !stopping, AudioQueueEnqueueBuffer(queue, buffer, 0, nil) != noErr {
                reportFailure()
            }
        } catch { reportFailure() }
    }

    private func checkRunning(_ queue: AudioQueueRef) {
        guard started, !stopping, !reportedEnd else { return }
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        if AudioQueueGetProperty(queue, kAudioQueueProperty_IsRunning, &running, &size) != noErr || running == 0 {
            reportFailure()
        }
    }

    private func reportFailure() {
        guard !reportedEnd, !stopping else { return }
        reportedEnd = true
        DispatchQueue.main.async { [weak self] in self?.onFailure?() }
    }
}

/// Shared native PCM writer, also exercised with synthetic samples in tests.
final class PCMRecordingFile {
    static var format: AudioStreamBasicDescription {
        AudioStreamBasicDescription(mSampleRate: 24_000, mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2, mChannelsPerFrame: 1,
            mBitsPerChannel: 16, mReserved: 0)
    }
    private var file: AudioFileID?
    private(set) var frames: Int64 = 0
    private let maximumFrames: Int64
    var reachedLimit: Bool { frames >= maximumFrames }

    init(url: URL, maximumFrames: Int64 = 24_000 * 300) throws {
        self.maximumFrames = maximumFrames
        var format = Self.format
        guard AudioFileCreateWithURL(url as CFURL, kAudioFileWAVEType, &format, .eraseFile, &file) == noErr else {
            throw AudioCaptureError.startFailed
        }
    }

    func write(_ bytes: UnsafeRawPointer, byteCount: UInt32) throws {
        guard let file, byteCount % 2 == 0 else { throw AudioCaptureError.deviceFailed }
        var count = UInt32(min(Int64(byteCount / 2), maximumFrames - frames))
        guard count > 0 else { return }
        let expected = count
        guard AudioFileWritePackets(file, false, count * 2, nil, frames, &count, bytes) == noErr else {
            throw AudioCaptureError.deviceFailed
        }
        frames += Int64(count)
        guard count == expected else { throw AudioCaptureError.deviceFailed }
    }

    func close() { if let file { AudioFileClose(file); self.file = nil } }
    deinit { close() }
}
