import CarPlay

@MainActor
final class CarPlayTemplateManager {
    private let interfaceController: CPInterfaceController
    private var voiceController: CarPlayVoiceController?

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }

    func setupRootTemplate() {
        let talkTab = CPListTemplate(
            title: "Talk",
            sections: [createTalkSection()]
        )
        talkTab.tabImage = UIImage(systemName: "mic.fill")

        let personasTab = CPListTemplate(
            title: "Personas",
            sections: [createPersonasSection()]
        )
        personasTab.tabImage = UIImage(systemName: "person.2.fill")

        let tabBar = CPTabBarTemplate(templates: [talkTab, personasTab])

        interfaceController.setRootTemplate(tabBar, animated: true) { _, _ in }
    }

    private func createTalkSection() -> CPListSection {
        let newConversation = CPListItem(
            text: "New Conversation",
            detailText: "Start talking with Sigmon"
        )
        newConversation.handler = { [weak self] _, completion in
            self?.startNewConversation()
            completion()
        }

        let continueConversation = CPListItem(
            text: "Continue Last",
            detailText: "Pick up where you left off"
        )
        continueConversation.handler = { [weak self] _, completion in
            self?.continueLastConversation()
            completion()
        }

        return CPListSection(items: [newConversation, continueConversation])
    }

    private func createPersonasSection() -> CPListSection {
        let sigmon = CPListItem(
            text: "Sigmon",
            detailText: "Default AI companion"
        )
        return CPListSection(items: [sigmon])
    }

    private func startNewConversation() {
        // Check quota before starting
        guard checkQuota() else { return }
        voiceController = CarPlayVoiceController(
            interfaceController: interfaceController
        )
    }

    private func continueLastConversation() {
        guard checkQuota() else { return }
        voiceController = CarPlayVoiceController(
            interfaceController: interfaceController
        )
    }

    /// Returns true if user has remaining quota; shows alert if exhausted
    private func checkQuota() -> Bool {
        let tier = UserDefaults.standard.string(forKey: "effectiveTier")
            .flatMap { SubscriptionTier(rawValue: $0) } ?? .free

        if tier == .byok { return true }

        let remaining = UserDefaults.standard.integer(forKey: "remainingMinutes")
        if remaining <= 0 {
            showQuotaExhaustedAlert()
            return false
        }
        return true
    }

    private func showQuotaExhaustedAlert() {
        let alert = CPAlertTemplate(
            titleVariants: ["Minutes Exhausted"],
            actions: [
                CPAlertAction(title: "OK", style: .cancel) { _ in
                    self.interfaceController.dismissTemplate(animated: true) { _, _ in }
                }
            ]
        )
        interfaceController.presentTemplate(alert, animated: true) { _, _ in }
    }
}
