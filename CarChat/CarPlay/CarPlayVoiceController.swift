import CarPlay

@MainActor
final class CarPlayVoiceController {
    private let interfaceController: CPInterfaceController

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }

    // Bridges VoiceSession.state -> CarPlay now-playing template updates
    // Full implementation will connect to VoiceSessionProtocol in a future release
}
