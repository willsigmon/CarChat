import SwiftUI
import SwiftData

@Observable
@MainActor
final class AppServices {
    let modelContainer: ModelContainer
    let keychainManager: KeychainManager
    let conversationStore: ConversationStore

    private(set) var isOnboardingComplete: Bool

    init() {
        let schema = Schema([
            Conversation.self,
            Message.self,
            Persona.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        self.keychainManager = KeychainManager()
        self.conversationStore = ConversationStore(
            modelContainer: modelContainer
        )
        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: "onboardingComplete"
        )
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }

    func seedDefaultPersonaIfNeeded() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Persona>(
            predicate: #Predicate { $0.isDefault == true }
        )

        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        guard let url = Bundle.main.url(
            forResource: "SigmonPersona",
            withExtension: "json"
        ),
        let data = try? Data(contentsOf: url),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let persona = Persona(
            name: json["name"] as? String ?? "Sigmon",
            personality: json["personality"] as? String ?? "",
            systemPrompt: json["systemPrompt"] as? String ?? "",
            isDefault: true,
            openAIRealtimeVoice: json["openAIRealtimeVoice"] as? String ?? "alloy",
            geminiVoice: json["geminiVoice"] as? String ?? "Kore",
            elevenLabsVoiceID: json["elevenLabsVoiceID"] as? String,
            systemTTSVoice: json["systemTTSVoice"] as? String
        )

        context.insert(persona)
        try? context.save()
    }
}
