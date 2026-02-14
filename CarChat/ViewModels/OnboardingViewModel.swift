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
        Task {
            hasMicPermission = await AVAudioApplication.requestRecordPermission()
            let status = await Self.requestSpeechAuthorization()
            hasSpeechPermission = status == .authorized
        }
    }

    /// Must be nonisolated so the callback closure doesn't inherit MainActor isolation.
    /// SFSpeechRecognizer.requestAuthorization calls back on a background queue;
    /// Swift 6 runtime crashes if the closure is MainActor-isolated.
    private nonisolated static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
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

    func goBack() {
        switch currentStep {
        case .welcome: break
        case .permissions: currentStep = .welcome
        case .apiKey: currentStep = .permissions
        case .ready: currentStep = .apiKey
        }
    }
}

enum OnboardingStep: CaseIterable {
    case welcome
    case permissions
    case apiKey
    case ready
}
