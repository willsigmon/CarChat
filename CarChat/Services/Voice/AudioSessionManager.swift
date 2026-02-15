import AVFoundation

@MainActor
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private static let outputModeKey = "audioOutputMode"
    private let audioSession = AVAudioSession.sharedInstance()

    private init() {}

    func configureForVoiceChat() throws {
        let outputMode = preferredOutputMode
        let options = categoryOptions(for: outputMode)

        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: options
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        try applyPreferredInput(for: outputMode)
        try applyOutputOverride(for: outputMode)
    }

    func deactivate() throws {
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    var preferredOutputMode: AudioOutputMode {
        guard
            let raw = UserDefaults.standard.string(forKey: Self.outputModeKey),
            let mode = AudioOutputMode(rawValue: raw)
        else {
            return .defaultMode
        }
        return mode
    }

    func setPreferredOutputMode(_ mode: AudioOutputMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: Self.outputModeKey)
        if audioSession.category == .playAndRecord {
            try? configureForVoiceChat()
        }
    }

    var currentOutputRouteName: String {
        audioSession.currentRoute.outputs.first?.portName ?? "Unknown"
    }

    private func applyOutputOverride(for mode: AudioOutputMode) throws {
        switch mode {
        case .automatic:
            try audioSession.overrideOutputAudioPort(.none)
        case .speakerphone:
            try audioSession.overrideOutputAudioPort(.speaker)
        }
    }

    private func applyPreferredInput(for mode: AudioOutputMode) throws {
        switch mode {
        case .automatic:
            try audioSession.setPreferredInput(nil)
        case .speakerphone:
            if let builtInMic = audioSession.availableInputs?.first(
                where: { $0.portType == .builtInMic }
            ) {
                try audioSession.setPreferredInput(builtInMic)
            } else {
                try audioSession.setPreferredInput(nil)
            }
        }
    }

    private func categoryOptions(for mode: AudioOutputMode) -> AVAudioSession.CategoryOptions {
        switch mode {
        case .automatic:
            return [
                .allowBluetoothHFP,
                .allowBluetoothA2DP,
                .duckOthers
            ]
        case .speakerphone:
            return [
                .defaultToSpeaker,
                .duckOthers
            ]
        }
    }

    var isBluetoothConnected: Bool {
        audioSession.currentRoute.outputs.contains { output in
            output.portType == .bluetoothA2DP
            || output.portType == .bluetoothHFP
            || output.portType == .bluetoothLE
        }
    }

    var sampleRate: Double {
        audioSession.sampleRate
    }

    func observeInterruptions(
        handler: @escaping @Sendable (AVAudioSession.InterruptionType) -> Void
    ) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { notification in
            guard let typeValue = notification.userInfo?[
                AVAudioSessionInterruptionTypeKey
            ] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            handler(type)
        }
    }

    func observeRouteChanges(
        handler: @escaping @Sendable (AVAudioSession.RouteChangeReason) -> Void
    ) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { notification in
            guard let reasonValue = notification.userInfo?[
                AVAudioSessionRouteChangeReasonKey
            ] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }
            handler(reason)
        }
    }
}
