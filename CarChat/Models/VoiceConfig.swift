import Foundation

struct VoiceConfig: Codable, Sendable {
    var ttsEngine: TTSEngineType
    var sttEnabled: Bool
    var vadSilenceThreshold: Double
    var vadSilenceDuration: Double

    static let `default` = VoiceConfig(
        ttsEngine: .system,
        sttEnabled: true,
        vadSilenceThreshold: -40.0,
        vadSilenceDuration: 1.5
    )
}

enum TTSEngineType: String, Codable, Sendable, CaseIterable, Identifiable {
    case system
    case elevenLabs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System (AVSpeechSynthesizer)"
        case .elevenLabs: "ElevenLabs"
        }
    }
}
