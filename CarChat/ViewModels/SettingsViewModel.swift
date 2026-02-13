import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    private let appServices: AppServices

    var selectedProvider: AIProviderType = .openAI
    var apiKeys: [AIProviderType: String] = [:]
    var keyValidationStatus: [AIProviderType: KeyValidationStatus] = [:]

    init(appServices: AppServices) {
        self.appServices = appServices
        loadKeys()
    }

    func loadKeys() {
        Task {
            for provider in AIProviderType.allCases where provider.requiresAPIKey {
                let key = try? await appServices.keychainManager.getAPIKey(
                    for: provider
                )
                apiKeys[provider] = key ?? ""
            }
        }
    }

    func saveKey(for provider: AIProviderType, key: String) {
        Task {
            do {
                if key.isEmpty {
                    try await appServices.keychainManager.deleteAPIKey(
                        for: provider
                    )
                } else {
                    try await appServices.keychainManager.saveAPIKey(
                        for: provider,
                        key: key
                    )
                }
                apiKeys[provider] = key
                keyValidationStatus[provider] = .saved
            } catch {
                keyValidationStatus[provider] = .error(error.localizedDescription)
            }
        }
    }
}

enum KeyValidationStatus: Equatable {
    case none
    case validating
    case valid
    case invalid(String)
    case saved
    case error(String)
}
