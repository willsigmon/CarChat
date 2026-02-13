import CarPlay

@MainActor
final class CarPlayTemplateManager {
    private let interfaceController: CPInterfaceController

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
        // Will be implemented in Phase 5
    }

    private func continueLastConversation() {
        // Will be implemented in Phase 5
    }
}
