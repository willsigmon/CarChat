import Foundation

enum AIProviderType: String, CaseIterable, Codable, Sendable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case grok = "grok"
    case apple = "apple"
    case ollama = "ollama"
    case openclaw = "openclaw"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Google Gemini"
        case .grok: "xAI Grok"
        case .apple: "Apple Intelligence"
        case .ollama: "Ollama"
        case .openclaw: "OpenClaw (Marlin)"
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
        case .openclaw: "Marlin"
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
        case .openclaw: "Your personal AI agent. Self-hosted."
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
        case .openclaw: "gemini-3-flash-preview"
        }
    }

    var supportsRealtimeVoice: Bool {
        switch self {
        case .openAI, .gemini: true
        case .anthropic, .grok, .apple, .ollama, .openclaw: false
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama, .apple, .openclaw: false
        default: true
        }
    }

    /// Whether this provider runs on-device (no network needed)
    var isLocal: Bool {
        switch self {
        case .apple, .ollama: true
        case .openclaw: false
        default: false
        }
    }

    var baseURL: String? {
        switch self {
        case .grok: "https://api.x.ai/v1"
        case .ollama: "http://localhost:11434/v1"
        case .openclaw:
            UserDefaults.standard.string(forKey: "openclawBaseURL")
                ?? "http://sigserve.tail1234.ts.net:8101"
        default: nil
        }
    }

    var keychainKey: String {
        "carchat.apikey.\(rawValue)"
    }

    /// Whether this provider is self-hosted (needs network but not a commercial API key)
    var isSelfHosted: Bool {
        switch self {
        case .openclaw: true
        default: false
        }
    }

    /// Cloud providers that need API keys
    static var cloudProviders: [AIProviderType] {
        allCases.filter { $0.requiresAPIKey }
    }

    /// Local/on-device providers
    static var localProviders: [AIProviderType] {
        allCases.filter { $0.isLocal }
    }

    /// Self-hosted providers (separate section in settings)
    static var selfHostedProviders: [AIProviderType] {
        allCases.filter { $0.isSelfHosted }
    }
}
