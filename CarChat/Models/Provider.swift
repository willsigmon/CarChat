import Foundation

enum AIProviderType: String, CaseIterable, Codable, Sendable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case grok = "grok"
    case apple = "apple"
    case ollama = "ollama"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Google Gemini"
        case .grok: "xAI Grok"
        case .apple: "Apple Intelligence"
        case .ollama: "Ollama"
        }
    }

    /// Compact name for small chips and badges
    var shortName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Claude"
        case .gemini: "Gemini"
        case .grok: "Grok"
        case .apple: "Apple"
        case .ollama: "Ollama"
        }
    }

    /// Short, fun tagline for the provider card
    var tagline: String {
        switch self {
        case .openAI: "The OG. GPT-4o and friends."
        case .anthropic: "Claude thinks before it speaks."
        case .gemini: "Google's multimodal brainchild."
        case .grok: "Unfiltered. Built by xAI."
        case .apple: "Private. On-device. Just works."
        case .ollama: "Run your own models, locally."
        }
    }

    /// The default model for each provider
    var defaultModel: String {
        switch self {
        case .openAI: "gpt-4o"
        case .anthropic: "claude-sonnet-4-5-20250929"
        case .gemini: "gemini-2.0-flash"
        case .grok: "grok-2"
        case .apple: "apple-foundation"
        case .ollama: "llama3.2"
        }
    }

    var supportsRealtimeVoice: Bool {
        switch self {
        case .openAI, .gemini: true
        case .anthropic, .grok, .apple, .ollama: false
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama, .apple: false
        default: true
        }
    }

    /// Whether this provider runs on-device (no network needed)
    var isLocal: Bool {
        switch self {
        case .apple, .ollama: true
        default: false
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

    /// Cloud providers that need API keys
    static var cloudProviders: [AIProviderType] {
        allCases.filter { $0.requiresAPIKey }
    }

    /// Local/on-device providers
    static var localProviders: [AIProviderType] {
        allCases.filter { $0.isLocal }
    }
}
