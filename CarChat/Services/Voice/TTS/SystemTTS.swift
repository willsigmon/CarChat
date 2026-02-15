import AVFoundation

@MainActor
final class SystemTTS: NSObject, TTSEngineProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    private var voiceIdentifier: String?
    private var speakingContinuation: CheckedContinuation<Void, Never>?

    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func setVoice(identifier: String?) {
        self.voiceIdentifier = identifier
    }

    func speak(_ text: String) async {
        guard !text.isEmpty else { return }

        stop()
        try? AudioSessionManager.shared.configureForVoiceChat()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if let voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        isSpeaking = true

        await withCheckedContinuation { continuation in
            self.speakingContinuation = continuation
            self.synthesizer.speak(utterance)
        }

        isSpeaking = false
    }

    func stop() {
        // Resume continuation BEFORE stopping the synthesizer to avoid
        // a race where the didCancel delegate also tries to resume it.
        completeSpeaking()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func completeSpeaking() {
        // Grab-and-nil atomically so only one caller ever resumes.
        guard let continuation = speakingContinuation else { return }
        speakingContinuation = nil
        isSpeaking = false
        continuation.resume()
    }
}

extension SystemTTS: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.completeSpeaking()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.completeSpeaking()
        }
    }
}
