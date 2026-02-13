import AVFoundation

@MainActor
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private let audioSession = AVAudioSession.sharedInstance()

    private init() {}

    func configureForVoiceChat() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .duckOthers,
                .defaultToSpeaker
            ]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func deactivate() throws {
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
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
