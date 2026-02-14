import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class ConversationViewModel {
    private let appServices: AppServices
    private var voiceSession: PipelineVoiceSession?
    private var stateTask: Task<Void, Never>?
    private var transcriptTask: Task<Void, Never>?
    private var audioLevelTask: Task<Void, Never>?

    private(set) var conversation: Conversation?
    private(set) var voiceState: VoiceSessionState = .idle
    private(set) var audioLevel: Float = 0
    private(set) var currentTranscript = ""
    private(set) var assistantTranscript = ""
    private(set) var errorMessage: String?

    var isListening: Bool { voiceState == .listening }
    var isProcessing: Bool { voiceState == .processing }
    var isSpeaking: Bool { voiceState == .speaking }
    var isActive: Bool { voiceState.isActive }

    init(appServices: AppServices) {
        self.appServices = appServices
    }

    // MARK: - Voice Control

    func toggleListening() {
        if isActive {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        errorMessage = nil

        Task {
            do {
                let session = try await buildVoiceSession()
                voiceSession = session

                if conversation == nil {
                    let persona = fetchActivePersona()
                    let providerType = await resolveProviderType()
                    conversation = appServices.conversationStore.create(
                        providerType: providerType,
                        personaName: persona?.name ?? "Sigmon"
                    )
                }

                observeStreams(session)

                let systemPrompt = fetchActivePersona()?.systemPrompt ?? ""
                try await session.start(systemPrompt: systemPrompt)
            } catch {
                voiceState = .idle
                errorMessage = error.localizedDescription
            }
        }
    }

    func sendPrompt(_ text: String) {
        errorMessage = nil

        Task {
            do {
                let session = try await buildVoiceSession()
                voiceSession = session

                if conversation == nil {
                    let persona = fetchActivePersona()
                    let providerType = await resolveProviderType()
                    conversation = appServices.conversationStore.create(
                        providerType: providerType,
                        personaName: persona?.name ?? "Sigmon"
                    )
                }

                observeStreams(session)

                let systemPrompt = fetchActivePersona()?.systemPrompt ?? ""
                await session.sendText(text, systemPrompt: systemPrompt)
            } catch {
                voiceState = .idle
                errorMessage = error.localizedDescription
            }
        }
    }

    func stopListening() {
        Task {
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
                    if transcript.isFinal, !transcript.text.isEmpty {
                        self.persistMessage(role: .user, content: transcript.text)
                    }
                } else if transcript.role == .assistant {
                    self.assistantTranscript = transcript.text
                    if transcript.isFinal, !transcript.text.isEmpty {
                        self.persistMessage(role: .assistant, content: transcript.text)
                        // Clear transcripts after assistant finishes
                        // (next listening loop will reset)
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1))
                            self.currentTranscript = ""
                            self.assistantTranscript = ""
                        }
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
}
