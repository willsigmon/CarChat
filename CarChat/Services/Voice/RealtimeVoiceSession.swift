import Foundation
import SwiftOpenAI

@MainActor
final class RealtimeVoiceSession: VoiceSessionProtocol {
    private let apiKey: String
    private let voice: String
    private let model: String

    private var stateContinuation: AsyncStream<VoiceSessionState>.Continuation?
    private var transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?
    private var audioLevelContinuation: AsyncStream<Float>.Continuation?

    private(set) var state: VoiceSessionState = .idle

    let stateStream: AsyncStream<VoiceSessionState>
    let transcriptStream: AsyncStream<VoiceTranscript>
    let audioLevelStream: AsyncStream<Float>

    init(apiKey: String, voice: String = "alloy", model: String = "gpt-4o-realtime-preview") {
        self.apiKey = apiKey
        self.voice = voice
        self.model = model

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
        updateState(.listening)

        // OpenAI Realtime API connection via SwiftOpenAI
        // The actual WebSocket connection will use SwiftOpenAI's realtime capabilities.
        // For now, this establishes the session structure.
        // Full implementation depends on SwiftOpenAI's Realtime API surface.

        // TODO: Connect to OpenAI Realtime WebSocket
        // 1. Create realtime session with model and voice
        // 2. Send session.update with system prompt
        // 3. Start audio input stream
        // 4. Handle server events (audio delta, transcript, etc.)
    }

    func stop() async {
        updateState(.idle)
        try? AudioSessionManager.shared.deactivate()
    }

    func interrupt() async {
        updateState(.listening)
        // Send conversation.item.truncate to OpenAI
    }

    private func updateState(_ newState: VoiceSessionState) {
        state = newState
        stateContinuation?.yield(newState)
    }
}
