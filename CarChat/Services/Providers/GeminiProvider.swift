import Foundation

final class GeminiProvider: AIProvider, @unchecked Sendable {
    let providerType: AIProviderType = .gemini
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gemini-2.0-flash") {
        self.apiKey = apiKey
        self.model = model
    }

    func streamChat(
        messages: [ChatMessage]
    ) async throws -> AsyncThrowingStream<String, Error> {
        let url = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse&key=\(apiKey)"
        )!

        var contents: [[String: Any]] = []
        var systemInstruction: [String: Any]?

        for msg in messages {
            switch msg.role {
            case .system:
                systemInstruction = [
                    "parts": [["text": msg.content]]
                ]
            case .user:
                contents.append([
                    "role": "user",
                    "parts": [["text": msg.content]]
                ])
            case .assistant:
                contents.append([
                    "role": "model",
                    "parts": [["text": msg.content]]
                ])
            }
        }

        var body: [String: Any] = ["contents": contents]
        if let systemInstruction {
            body["systemInstruction"] = systemInstruction
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIProviderError.networkError("Gemini API error")
        }

        let (outputStream, continuation) = AsyncThrowingStream.makeStream(of: String.self)

        Task {
            do {
                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let jsonString = String(line.dropFirst(6))
                    guard let data = jsonString.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(
                              with: data
                          ) as? [String: Any],
                          let candidates = json["candidates"] as? [[String: Any]],
                          let content = candidates.first?["content"] as? [String: Any],
                          let parts = content["parts"] as? [[String: Any]],
                          let text = parts.first?["text"] as? String else {
                        continue
                    }
                    continuation.yield(text)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return outputStream
    }

    func validateKey() async throws -> Bool {
        let url = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        )!

        let (_, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        return httpResponse.statusCode == 200
    }
}
