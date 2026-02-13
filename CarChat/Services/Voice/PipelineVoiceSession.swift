import Foundation

@MainActor
final class PipelineVoiceSession: VoiceSessionProtocol {
    private let sttEngine: STTEngine
    private let ttsEngine: TTSEngineProtocol
    private let aiProvider: AIProvider
    private let systemPrompt: String

    private var stateContinuation: AsyncStream<VoiceSessionState>.Continuation?
    private var transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?
    private var audioLevelContinuation: AsyncStream<Float>.Continuation?

    private var listeningTask: Task<Void, Never>?
    private var conversationHistory: [(role: MessageRole, content: String)] = []

    private(set) var state: VoiceSessionState = .idle

    let stateStream: AsyncStream<VoiceSessionState>
    let transcriptStream: AsyncStream<VoiceTranscript>
    let audioLevelStream: AsyncStream<Float>

    init(
        sttEngine: STTEngine,
        ttsEngine: TTSEngineProtocol,
        aiProvider: AIProvider,
        systemPrompt: String = ""
    ) {
        self.sttEngine = sttEngine
        self.ttsEngine = ttsEngine
        self.aiProvider = aiProvider
        self.systemPrompt = systemPrompt

        var stateCont: AsyncStream<VoiceSessionState>.Continuation!
        self.stateStream = AsyncStream { stateCont = $0 }
        self.stateContinuation = stateCont

        var transcriptCont: AsyncStream<VoiceTranscript>.Continuation!
        self.transcriptStream = AsyncStream { transcriptCont = $0 }
        self.transcriptContinuation = transcriptCont

        var audioLevelCont: AsyncStream<Float>.Continuation!
        self.audioLevelStream = AsyncStream { audioLevelCont = $0 }
        self.audioLevelContinuation = audioLevelCont
    }

    func start(systemPrompt: String) async throws {
        try AudioSessionManager.shared.configureForVoiceChat()

        if !systemPrompt.isEmpty {
            conversationHistory.append((.system, systemPrompt))
        }

        startListeningLoop()
    }

    func stop() async {
        listeningTask?.cancel()
        listeningTask = nil
        await sttEngine.stopListening()
        ttsEngine.stop()
        updateState(.idle)
        try? AudioSessionManager.shared.deactivate()
    }

    func interrupt() async {
        ttsEngine.stop()
        updateState(.listening)
    }

    private func startListeningLoop() {
        listeningTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                updateState(.listening)

                do {
                    try await sttEngine.startListening()
                } catch {
                    updateState(.error(error.localizedDescription))
                    return
                }

                // Forward audio levels
                let levelTask = Task { [weak self] in
                    guard let self else { return }
                    for await level in sttEngine.audioLevelStream {
                        audioLevelContinuation?.yield(level)
                    }
                }

                // Wait for final transcript
                var finalText = ""
                for await transcript in sttEngine.transcriptStream {
                    transcriptContinuation?.yield(transcript)
                    if transcript.isFinal {
                        finalText = transcript.text
                        break
                    }
                }

                levelTask.cancel()
                await sttEngine.stopListening()

                guard !finalText.isEmpty, !Task.isCancelled else { continue }

                // Process through AI
                updateState(.processing)
                conversationHistory.append((.user, finalText))

                do {
                    var fullResponse = ""
                    let stream = try await aiProvider.streamChat(
                        messages: conversationHistory.map {
                            ChatMessage(role: $0.role, content: $0.content)
                        }
                    )

                    updateState(.speaking)

                    // Collect response and speak in sentence chunks
                    var sentenceBuffer = ""
                    for try await chunk in stream {
                        fullResponse += chunk
                        sentenceBuffer += chunk

                        // Speak when we hit sentence boundaries
                        if let range = sentenceBuffer.range(
                            of: "[.!?]\\ ",
                            options: .regularExpression
                        ) {
                            let sentence = String(
                                sentenceBuffer[..<range.upperBound]
                            )
                            sentenceBuffer = String(
                                sentenceBuffer[range.upperBound...]
                            )
                            await ttsEngine.speak(sentence)
                        }
                    }

                    // Speak remaining text
                    if !sentenceBuffer.isEmpty {
                        await ttsEngine.speak(sentenceBuffer)
                    }

                    conversationHistory.append((.assistant, fullResponse))
                    transcriptContinuation?.yield(
                        VoiceTranscript(
                            text: fullResponse,
                            isFinal: true,
                            role: .assistant
                        )
                    )
                } catch {
                    updateState(.error(error.localizedDescription))
                }
            }
        }
    }

    private func updateState(_ newState: VoiceSessionState) {
        state = newState
        stateContinuation?.yield(newState)
    }
}
