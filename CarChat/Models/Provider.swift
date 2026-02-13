import Foundation

enum AIProviderType: String, CaseIterable, Codable, Sendable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case grok = "grok"
    case ollama = "ollama"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic (Claude)"
        case .gemini: "Google Gemini"
        case .grok: "xAI Grok"
        case .ollama: "Ollama (Local)"
        }
    }

    var supportsRealtimeVoice: Bool {
        switch self {
        case .openAI, .gemini: true
        case .anthropic, .grok, .ollama: false
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama: false
        default: true
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: "gpt-4o"
        case .anthropic: "claude-sonnet-4-5-20250929"
        case .gemini: "gemini-2.0-flash"
        case .grok: "grok-2"
        case .ollama: "llama3.2"
        }
    }

    var baseURL: String? {
        switch self {
        case .grok: "https://api.x.ai/v1"
        case .ollama: "http://localhost:11434/v1"
        default: nil
        }
    }

    var keychainKey: String {
        "carchat.apikey.\(rawValue)"
    }
}
