import Foundation
import AVFoundation

@MainActor
final class ElevenLabsTTS: TTSEngineProtocol {
    private let apiKey: String
    private let voiceID: String
    private var audioPlayer: AVAudioPlayer?

    private(set) var isSpeaking = false

    init(apiKey: String, voiceID: String = "21m00Tcm4TlvDq8ikWAM") {
        self.apiKey = apiKey
        self.voiceID = voiceID
    }

    func speak(_ text: String) async {
        guard !text.isEmpty else { return }

        stop()
        isSpeaking = true

        do {
            let audioData = try await synthesize(text: text)
            try await playAudio(data: audioData)
        } catch {
            isSpeaking = false
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    private func synthesize(text: String) async throws -> Data {
        let url = URL(
            string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.prepareToPlay()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let delegate = AudioPlayerDelegate {
                continuation.resume()
            }
            self.audioPlayer?.delegate = delegate
            // Hold reference
            objc_setAssociatedObject(
                self.audioPlayer as Any,
                "delegate",
                delegate,
                .OBJC_ASSOCIATION_RETAIN
            )
            self.audioPlayer?.play()
        }

        isSpeaking = false
    }
}

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        completion()
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
