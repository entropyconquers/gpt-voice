import SwiftUI

struct MicrophonePicker: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: AppPreferences

    init(model: AppModel) {
        self.model = model
        preferences = model.preferences
    }

    var body: some View {
        SettingsRow(title: "Microphone", detail: model.preferredMicrophoneUnavailable
            ? "Selected microphone unavailable. New recordings use System Default until it reconnects."
            : "Choose an input for GPT Voice without changing your Mac's sound settings.") {
            Picker("Recording microphone", selection: Binding(get: { preferences.preferredMicrophoneUID },
                set: { model.setPreferredMicrophone($0) })) {
                Text("System Default").tag("")
                ForEach(model.inputDevices) { device in Text(device.name).tag(device.uid) }
                if model.preferredMicrophoneUnavailable {
                    Text("\(preferences.preferredMicrophoneName.isEmpty ? "Selected microphone" : preferences.preferredMicrophoneName) (unavailable)")
                        .tag(preferences.preferredMicrophoneUID)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 230)
            .accessibilityLabel("Recording microphone")
            .disabled(!model.canChangeSettings)
        }
    }
}
