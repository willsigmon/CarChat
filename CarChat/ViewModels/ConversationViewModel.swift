import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class ConversationViewModel {
    private let appServices: AppServices
    private var voiceSession: PipelineVoiceSession?
    private var startTask: Task<Void, Never>?
    private var sendTask: Task<Void, Never>?
    private var stateTask: Task<Void, Never>?
    private var transcriptTask: Task<Void, Never>?
    private var audioLevelTask: Task<Void, Never>?
    private var activeUserBubbleID: UUID?
    private var activeAssistantBubbleID: UUID?

    private(set) var conversation: Conversation?
    private(set) var voiceState: VoiceSessionState = .idle
    private(set) var audioLevel: Float = 0
    private(set) var currentTranscript = ""
    private(set) var assistantTranscript = ""
    private(set) var errorMessage: String?
    private(set) var activeProvider: AIProviderType
    private(set) var bubbles: [ConversationBubble] = []

    var isListening: Bool { voiceState == .listening }
    var isProcessing: Bool { voiceState == .processing }
    var isSpeaking: Bool { voiceState == .speaking }
    var isActive: Bool { voiceState.isActive }

    init(appServices: AppServices) {
        self.appServices = appServices
        let storedProvider = UserDefaults.standard.string(forKey: "selectedProvider")
        self.activeProvider = AIProviderType(rawValue: storedProvider ?? "") ?? .openAI
    }

    // MARK: - Voice Control

    func toggleListening() {
        if isActive || voiceSession != nil || startTask != nil {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        guard startTask == nil, sendTask == nil, voiceSession == nil else { return }
        errorMessage = nil

        startTask = Task { [weak self] in
            guard let self else { return }
            defer { startTask = nil }

            do {
                let session = try await buildVoiceSession()
                voiceSession = session

                if conversation == nil {
                    let persona = fetchActivePersona()
                    conversation = appServices.conversationStore.create(
                        providerType: activeProvider,
                        personaName: persona?.name ?? "Sigmon"
                    )
                    resetBubbleDraftState()
                    bubbles = []
                }

                observeStreams(session)

                let systemPrompt = fetchActivePersona()?.systemPrompt ?? ""
                try await session.start(systemPrompt: systemPrompt)
            } catch {
                if Task.isCancelled { return }
                voiceState = .idle
                errorMessage = error.localizedDescription
                tearDownObservers()
                voiceSession = nil
            }
        }
    }

    func sendPrompt(_ text: String) {
        guard sendTask == nil else { return }
        errorMessage = nil

        sendTask = Task { [weak self] in
            guard let self else { return }
            defer { sendTask = nil }

            do {
                startTask?.cancel()
                startTask = nil

                if voiceSession != nil {
                    await voiceSession?.stop()
                    tearDownObservers()
                    voiceSession = nil
                }

                let session = try await buildVoiceSession()
                voiceSession = session

                if conversation == nil {
                    let persona = fetchActivePersona()
                    conversation = appServices.conversationStore.create(
                        providerType: activeProvider,
                        personaName: persona?.name ?? "Sigmon"
                    )
                    resetBubbleDraftState()
                    bubbles = []
                }

                observeStreams(session)

                let systemPrompt = fetchActivePersona()?.systemPrompt ?? ""
                await session.sendText(text, systemPrompt: systemPrompt)
            } catch {
                if Task.isCancelled { return }
                voiceState = .idle
                errorMessage = error.localizedDescription
                tearDownObservers()
                voiceSession = nil
            }
        }
    }

    func stopListening() {
        Task {
            startTask?.cancel()
            startTask = nil
            sendTask?.cancel()
            sendTask = nil
            await voiceSession?.stop()
            tearDownObservers()
            voiceSession = nil
            voiceState = .idle
            audioLevel = 0
        }
    }

    func interrupt() {
        Task {
            await voiceSession?.interrupt()
        }
    }

    // MARK: - Session Builder

    private func buildVoiceSession() async throws -> PipelineVoiceSession {
        let providerType = await resolveProviderType()
        activeProvider = providerType
        let apiKey: String? = try? await appServices.keychainManager.getAPIKey(for: providerType)

        let aiProvider = try AIProviderFactory.create(
            type: providerType,
            apiKey: apiKey
        )

        let stt = SFSpeechSTT(paceProfile: .fast)
        let tts = try await buildTTSEngine()

        return PipelineVoiceSession(
            sttEngine: stt,
            ttsEngine: tts,
            aiProvider: aiProvider
        )
    }

    private func buildTTSEngine() async throws -> TTSEngineProtocol {
        let engineType = TTSEngineType(
            rawValue: UserDefaults.standard.string(forKey: "ttsEngine") ?? "system"
        ) ?? .system

        switch engineType {
        case .system:
            let tts = SystemTTS()
            if let persona = fetchActivePersona(),
               let voiceId = persona.systemTTSVoice {
                tts.setVoice(identifier: voiceId)
            }
            return tts

        case .elevenLabs:
            guard let key = try? await appServices.keychainManager.getElevenLabsKey(),
                  !key.isEmpty else {
                // Fallback to system if no ElevenLabs key
                let tts = SystemTTS()
                if let persona = fetchActivePersona(),
                   let voiceId = persona.systemTTSVoice {
                    tts.setVoice(identifier: voiceId)
                }
                return tts
            }

            let modelRaw = UserDefaults.standard.string(forKey: "elevenLabsModel") ?? ElevenLabsModel.flash.rawValue
            let model = ElevenLabsModel(rawValue: modelRaw) ?? .flash

            let tts = ElevenLabsTTS(
                apiKey: key,
                model: model
            )

            // Apply persona's ElevenLabs voice if set
            if let persona = fetchActivePersona(),
               let voiceId = persona.elevenLabsVoiceID {
                tts.setVoice(id: voiceId)
            }

            return tts
        }
    }

    // MARK: - Stream Observers

    private func observeStreams(_ session: PipelineVoiceSession) {
        tearDownObservers()

        stateTask = Task { [weak self] in
            for await state in session.stateStream {
                guard let self, !Task.isCancelled else { break }
                self.voiceState = state
                if case .error(let msg) = state {
                    self.errorMessage = msg
                }
            }
        }

        transcriptTask = Task { [weak self] in
            for await transcript in session.transcriptStream {
                guard let self, !Task.isCancelled else { break }
                if transcript.role == .user {
                    self.currentTranscript = transcript.text
                    self.upsertBubble(transcript)
                    if transcript.isFinal, !transcript.text.isEmpty {
                        self.persistMessage(role: .user, content: transcript.text)
                    }
                } else if transcript.role == .assistant {
                    self.assistantTranscript = transcript.text
                    self.upsertBubble(transcript)
                    if transcript.isFinal, !transcript.text.isEmpty {
                        self.persistMessage(role: .assistant, content: transcript.text)
                    }
                }
            }
        }

        audioLevelTask = Task { [weak self] in
            for await level in session.audioLevelStream {
                guard let self, !Task.isCancelled else { break }
                self.audioLevel = level
            }
        }
    }

    private func tearDownObservers() {
        stateTask?.cancel()
        transcriptTask?.cancel()
        audioLevelTask?.cancel()
        stateTask = nil
        transcriptTask = nil
        audioLevelTask = nil
    }

    // MARK: - Persistence

    private func persistMessage(role: MessageRole, content: String) {
        guard let conversation else { return }
        _ = appServices.conversationStore.addMessage(
            to: conversation,
            role: role,
            content: content
        )
    }

    // MARK: - Helpers

    private func fetchActivePersona() -> Persona? {
        let context = appServices.modelContainer.mainContext
        let descriptor = FetchDescriptor<Persona>(
            predicate: #Predicate { $0.isDefault == true }
        )
        return (try? context.fetch(descriptor))?.first
    }

    private func resolveProviderType() async -> AIProviderType {
        // Use the conversation's provider if resuming
        if let conversation {
            return conversation.provider
        }
        // Use the provider the user chose during onboarding / settings
        if let saved = UserDefaults.standard.string(forKey: "selectedProvider"),
           let provider = AIProviderType(rawValue: saved) {
            return provider
        }
        // Fallback: find the first cloud provider that actually has a key saved
        for provider in AIProviderType.cloudProviders {
            if let hasKey = try? await appServices.keychainManager.hasAPIKey(for: provider),
               hasKey {
                return provider
            }
        }
        return .openAI
    }

    private func resetBubbleDraftState() {
        activeUserBubbleID = nil
        activeAssistantBubbleID = nil
    }

    private func upsertBubble(_ transcript: VoiceTranscript) {
        let trimmed = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let existingID: UUID?
        switch transcript.role {
        case .user:
            existingID = activeUserBubbleID
        case .assistant:
            existingID = activeAssistantBubbleID
        case .system:
            existingID = nil
        }

        if let existingID,
           let index = bubbles.firstIndex(where: { $0.id == existingID }) {
            bubbles[index] = ConversationBubble(
                id: existingID,
                role: transcript.role,
                text: trimmed,
                isFinal: transcript.isFinal,
                createdAt: bubbles[index].createdAt
            )
        } else {
            let bubble = ConversationBubble(
                role: transcript.role,
                text: trimmed,
                isFinal: transcript.isFinal
            )
            bubbles.append(bubble)
            switch transcript.role {
            case .user:
                activeUserBubbleID = bubble.id
            case .assistant:
                activeAssistantBubbleID = bubble.id
            case .system:
                break
            }
        }

        if transcript.isFinal {
            switch transcript.role {
            case .user:
                activeUserBubbleID = nil
            case .assistant:
                activeAssistantBubbleID = nil
            case .system:
                break
            }
        }

        if bubbles.count > 64 {
            bubbles.removeFirst(bubbles.count - 64)
        }
    }
}

struct ConversationBubble: Identifiable, Equatable, Sendable {
    let id: UUID
    let role: MessageRole
    let text: String
    let isFinal: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        isFinal: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.isFinal = isFinal
        self.createdAt = createdAt
    }
}
