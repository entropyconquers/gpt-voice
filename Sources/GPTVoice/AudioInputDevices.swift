import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Equatable {
    let uid: String
    let name: String
    var id: String { uid }
}

struct AudioInputDeviceProvider {
    var snapshot: () -> [AudioInputDevice] = AudioInputDevices.available
}

enum AudioInputDevices {
    /// Enumerates input-capable devices without opening the microphone.
    static func available() -> [AudioInputDevice] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr,
              size > 0 else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        let status = ids.withUnsafeMutableBytes {
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, $0.baseAddress!)
        }
        guard status == noErr else { return [] }
        return ids.compactMap { id -> AudioInputDevice? in
            var aliveAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsAlive,
                mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            var alive: UInt32 = 1
            var aliveSize = UInt32(MemoryLayout<UInt32>.size)
            if AudioObjectGetPropertyData(id, &aliveAddress, 0, nil, &aliveSize, &alive) == noErr, alive == 0 { return nil }
            var input = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeInput, mElement: kAudioObjectPropertyElementMain)
            var inputSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(id, &input, 0, nil, &inputSize) == noErr, inputSize > 0,
                  let uid = stringProperty(id, selector: kAudioDevicePropertyDeviceUID), !uid.isEmpty,
                  let name = stringProperty(id, selector: kAudioObjectPropertyName) else { return nil }
            return AudioInputDevice(uid: uid, name: name)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func stringProperty(_ device: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = withUnsafeMutablePointer(to: &value) {
            AudioObjectGetPropertyData(device, &address, 0, nil, &size, UnsafeMutableRawPointer($0))
        }
        guard status == noErr else { return nil }
        return value as String
    }

    /// An absent preference follows the system default without erasing the saved UID.
    static func resolvedUID(_ preferredUID: String, devices: [AudioInputDevice]) -> String? {
        devices.first { !$0.uid.isEmpty && $0.uid == preferredUID }?.uid
    }
}

@MainActor
final class AudioInputDeviceMonitor {
    private var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    private let listener: AudioObjectPropertyListenerBlock
    private var installed = false

    init(onChange: @escaping @MainActor () -> Void) {
        listener = { _, _ in onChange() }
        installed = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject),
            &address, .main, listener) == noErr
    }

    func stop() {
        guard installed else { return }
        AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
        installed = false
    }

    deinit {
        if installed {
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
        }
    }
}
