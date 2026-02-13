import Foundation
import SwiftUI

@Observable
@MainActor
final class ConversationViewModel {
    private let appServices: AppServices
    private(set) var conversation: Conversation?
    private(set) var isListening = false
    private(set) var audioLevel: Float = 0
    private(set) var currentTranscript = ""
    private(set) var isProcessing = false

    init(appServices: AppServices) {
        self.appServices = appServices
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        if conversation == nil {
            conversation = appServices.conversationStore.create()
        }
        isListening = true
        // Voice session will be connected in Phase 2
    }

    func stopListening() {
        isListening = false
        audioLevel = 0
        // Voice session will be disconnected in Phase 2
    }
}
