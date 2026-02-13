import Foundation
import SwiftUI
import Speech
import AVFoundation

@Observable
@MainActor
final class OnboardingViewModel {
    private let appServices: AppServices

    var currentStep: OnboardingStep = .welcome
    var selectedProvider: AIProviderType = .openAI
    var apiKey = ""
    var hasMicPermission = false
    var hasSpeechPermission = false

    init(appServices: AppServices) {
        self.appServices = appServices
    }

    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            Task { @MainActor in
                self.hasMicPermission = granted
            }
        }

        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.hasSpeechPermission = status == .authorized
            }
        }
    }

    func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        Task {
            try? await appServices.keychainManager.saveAPIKey(
                for: selectedProvider,
                key: apiKey
            )
        }
    }

    func completeOnboarding() {
        saveAPIKey()
        appServices.completeOnboarding()
    }

    func advance() {
        switch currentStep {
        case .welcome: currentStep = .permissions
        case .permissions: currentStep = .apiKey
        case .apiKey: currentStep = .ready
        case .ready: completeOnboarding()
        }
    }
}

enum OnboardingStep: CaseIterable {
    case welcome
    case permissions
    case apiKey
    case ready
}
