import CarPlay

@MainActor
final class CarPlayVoiceController {
    private let interfaceController: CPInterfaceController

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }

    // Will bridge VoiceSession.state -> CarPlay template updates in Phase 5
}
