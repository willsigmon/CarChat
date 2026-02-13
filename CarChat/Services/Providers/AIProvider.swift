import Foundation

struct ChatMessage: Sendable {
    let role: MessageRole
    let content: String
}

protocol AIProvider: Sendable {
    var providerType: AIProviderType { get }

    func streamChat(
        messages: [ChatMessage]
    ) async throws -> AsyncThrowingStream<String, Error>

    func validateKey() async throws -> Bool
}

enum AIProviderError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case rateLimited
    case modelUnavailable(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: "Invalid API key"
        case .networkError(let msg): "Network error: \(msg)"
        case .rateLimited: "Rate limited — please wait"
        case .modelUnavailable(let model): "Model unavailable: \(model)"
        case .unknown(let msg): "Error: \(msg)"
        }
    }
}
