import AppKit
import AVFoundation
import XCTest
@testable import GPTVoice

final class MicrophoneSelectionTests: XCTestCase {
    private let usb = AudioInputDevice(uid: "fixture-usb", name: "USB Microphone")
    private let builtIn = AudioInputDevice(uid: "fixture-built-in", name: "Built-in Microphone")

    @MainActor
    func testNativeSelectedDeviceRecordingWhenExplicitlyEnabled() async throws {
        guard let uid = ProcessInfo.processInfo.environment["GPT_VOICE_TEST_MICROPHONE_UID"] else {
            throw XCTSkip("Live microphone recording is opt-in.")
        }
        guard AudioCapture.microphoneStatus == .authorized else { throw XCTSkip("Microphone access is not granted to the test host.") }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("microphone-live-\(UUID().uuidString).wav")
        let recorder = try DeviceAudioRecorder(url: url, deviceUID: uid)
        defer { recorder.stop(); try? FileManager.default.removeItem(at: url) }
        var failed = false
        recorder.onFailure = { failed = true }
        try recorder.start()
        XCTAssertEqual(recorder.currentDeviceUID, uid)
        try await Task.sleep(nanoseconds: 300_000_000)
        recorder.stop()
        XCTAssertFalse(failed)
        let file = try AVAudioFile(forReading: url)
        XCTAssertGreaterThan(file.length, 0)
        XCTAssertEqual(file.fileFormat.sampleRate, 24_000)
        XCTAssertEqual(file.fileFormat.channelCount, 1)
        XCTAssertEqual(file.fileFormat.streamDescription.pointee.mBitsPerChannel, 16)

        // An unavailable saved device must still record through System Default.
        let fallback = AudioCapture()
        defer { fallback.cleanup() }
        try await fallback.start(preferredDeviceUID: "fixture-unplugged")
        try await Task.sleep(nanoseconds: 200_000_000)
        let fallbackURL = try fallback.stop()
        XCTAssertGreaterThan(try AVAudioFile(forReading: fallbackURL).length, 0)
    }

    @MainActor
    func testDisconnectKeepsThePreferenceUsesDefaultAndReconnectRestoresIt() {
        let suite = "microphone-selection-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        XCTAssertEqual(preferences.preferredMicrophoneUID, "")
        var devices = [usb, builtIn]
        let provider = AudioInputDeviceProvider(snapshot: { devices })
        let model = AppModel(preferences: preferences, inputDeviceProvider: provider)
        defer { model.cleanup() }
        model.setPreferredMicrophone(usb.uid)
        XCTAssertEqual(preferences.preferredMicrophoneName, usb.name)
        XCTAssertEqual(AppPreferences(defaults: defaults).preferredMicrophoneUID, usb.uid)
        XCTAssertEqual(AudioInputDevices.resolvedUID(preferences.preferredMicrophoneUID, devices: devices), usb.uid)

        devices = [builtIn]
        model.refreshInputDevices()
        XCTAssertTrue(model.preferredMicrophoneUnavailable)
        XCTAssertEqual(preferences.preferredMicrophoneUID, usb.uid)
        XCTAssertEqual(preferences.preferredMicrophoneName, usb.name)
        XCTAssertNil(AudioInputDevices.resolvedUID(preferences.preferredMicrophoneUID, devices: devices))

        devices = [usb, builtIn]
        model.refreshInputDevices()
        XCTAssertFalse(model.preferredMicrophoneUnavailable)
        XCTAssertEqual(AudioInputDevices.resolvedUID(preferences.preferredMicrophoneUID, devices: devices), usb.uid)
        model.setPreferredMicrophone("")
        XCTAssertEqual(preferences.preferredMicrophoneUID, "")
        XCTAssertEqual(preferences.preferredMicrophoneName, "")
    }

    @MainActor
    func testDeviceRenameUpdatesNameAndUnknownSelectionDoesNotReplacePreference() {
        let suite = "microphone-rename-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var devices = [usb]
        let model = AppModel(preferences: AppPreferences(defaults: defaults),
                             inputDeviceProvider: AudioInputDeviceProvider(snapshot: { devices }))
        defer { model.cleanup() }
        model.setPreferredMicrophone(usb.uid)
        devices = [AudioInputDevice(uid: usb.uid, name: "Renamed microphone")]
        model.refreshInputDevices()
        XCTAssertEqual(model.preferences.preferredMicrophoneName, "Renamed microphone")
        model.setPreferredMicrophone("missing")
        XCTAssertEqual(model.preferences.preferredMicrophoneUID, usb.uid)
    }

    func testNativeDeviceEnumerationHasStableNonemptyIdentifiers() {
        let devices = AudioInputDevices.available()
        XCTAssertEqual(Set(devices.map(\.uid)).count, devices.count)
        XCTAssertTrue(devices.allSatisfy { !$0.uid.isEmpty && !$0.name.isEmpty })
    }

    func testDeviceRecorderWriterProducesMono24kHz16BitWavAndHonoursTheCap() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("microphone-pcm-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try PCMRecordingFile(url: url, maximumFrames: 240)
        let samples = [Int16](repeating: 1000, count: 480)
        try samples.withUnsafeBytes { try writer.write($0.baseAddress!, byteCount: UInt32($0.count)) }
        XCTAssertTrue(writer.reachedLimit)
        XCTAssertEqual(writer.frames, 240)
        writer.close()
        let file = try AVAudioFile(forReading: url)
        XCTAssertEqual(file.fileFormat.sampleRate, 24_000)
        XCTAssertEqual(file.fileFormat.channelCount, 1)
        XCTAssertEqual(file.fileFormat.streamDescription.pointee.mBitsPerChannel, 16)
        XCTAssertEqual(file.length, 240)
    }

    func testWriterRejectsIncompletePcmSamplesAndClosesIdempotently() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("microphone-pcm-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try PCMRecordingFile(url: url)
        var byte: UInt8 = 0
        XCTAssertThrowsError(try writer.write(&byte, byteCount: 1))
        writer.close()
        writer.close()
        var sample: Int16 = 0
        XCTAssertThrowsError(try writer.write(&sample, byteCount: 2))
    }
}
