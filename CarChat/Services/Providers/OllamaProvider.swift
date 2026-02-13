import Foundation

final class OllamaProvider: AIProvider, @unchecked Sendable {
    let providerType: AIProviderType = .ollama
    private let baseURL: String
    private let model: String

    init(
        baseURL: String = "http://localhost:11434",
        model: String = "llama3.2"
    ) {
        self.baseURL = baseURL
        self.model = model
    }

    func streamChat(
        messages: [ChatMessage]
    ) async throws -> AsyncThrowingStream<String, Error> {
        let url = URL(string: "\(baseURL)/v1/chat/completions")!

        let openAIMessages = messages.map { msg -> [String: String] in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "messages": openAIMessages,
            "stream": true
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        nonisolated(unsafe) let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIProviderError.networkError("Ollama not running at \(baseURL)")
        }

        let (outputStream, continuation) = AsyncThrowingStream.makeStream(of: String.self)

        Task {
            do {
                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let jsonString = String(line.dropFirst(6))
                    if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                        break
                    }
                    guard let data = jsonString.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(
                              with: data
                          ) as? [String: Any],
                          let choices = json["choices"] as? [[String: Any]],
                          let delta = choices.first?["delta"] as? [String: Any],
                          let content = delta["content"] as? String else {
                        continue
                    }
                    continuation.yield(content)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return outputStream
    }

    func validateKey() async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/tags")!
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}
