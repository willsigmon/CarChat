import Foundation

enum AIProviderFactory {
    static func create(
        type: AIProviderType,
        apiKey: String?,
        model: String? = nil
    ) throws -> AIProvider {
        switch type {
        case .openAI:
            guard let apiKey, !apiKey.isEmpty else {
                throw AIProviderError.invalidAPIKey
            }
            return OpenAIProvider(
                apiKey: apiKey,
                model: model ?? type.defaultModel
            )

        case .anthropic:
            guard let apiKey, !apiKey.isEmpty else {
                throw AIProviderError.invalidAPIKey
            }
            return AnthropicProvider(
                apiKey: apiKey,
                model: model ?? type.defaultModel
            )

        case .gemini:
            guard let apiKey, !apiKey.isEmpty else {
                throw AIProviderError.invalidAPIKey
            }
            return GeminiProvider(
                apiKey: apiKey,
                model: model ?? type.defaultModel
            )

        case .grok:
            guard let apiKey, !apiKey.isEmpty else {
                throw AIProviderError.invalidAPIKey
            }
            return GrokProvider(
                apiKey: apiKey,
                model: model ?? type.defaultModel
            )

        case .ollama:
            return OllamaProvider(
                model: model ?? type.defaultModel
            )
        }
    }
}
