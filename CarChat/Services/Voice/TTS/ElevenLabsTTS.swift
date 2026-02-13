import Foundation
import AVFoundation

@MainActor
final class ElevenLabsTTS: NSObject, TTSEngineProtocol {
    private let apiKey: String
    private let voiceID: String
    private var audioPlayer: AVAudioPlayer?
    private var playbackContinuation: CheckedContinuation<Void, Never>?

    private(set) var isSpeaking = false

    init(apiKey: String, voiceID: String = "21m00Tcm4TlvDq8ikWAM") {
        self.apiKey = apiKey
        self.voiceID = voiceID
        super.init()
    }

    func speak(_ text: String) async {
        guard !text.isEmpty else { return }

        stop()
        isSpeaking = true

        do {
            let audioData = try await synthesize(text: text)
            try await playAudio(data: audioData)
        } catch {
            // Synthesis or playback failed
        }
        isSpeaking = false
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
        audioPlayer = nil
        // Resume any waiting continuation so the caller isn't stuck
        playbackContinuation?.resume()
        playbackContinuation = nil
        isSpeaking = false
    }

    private func synthesize(text: String) async throws -> Data {
        guard let url = URL(
            string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)"
        ) else {
            throw ElevenLabsError.synthesizeFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_turbo_v2_5",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.0,
                "use_speaker_boost": true
            ]
        ]

        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ElevenLabsError.synthesizeFailed
        }

        return data
    }

    private func playAudio(data: Data) async throws {
        let player = try AVAudioPlayer(data: data)
        audioPlayer = player
        player.delegate = self
        player.prepareToPlay()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.playbackContinuation = continuation
            player.play()
        }
    }
}

extension ElevenLabsTTS: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor in
            self.playbackContinuation?.resume()
            self.playbackContinuation = nil
        }
    }
}

enum ElevenLabsError: LocalizedError {
    case synthesizeFailed
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .synthesizeFailed: "ElevenLabs synthesis failed"
        case .apiKeyMissing: "ElevenLabs API key not configured"
        }
    }
}
