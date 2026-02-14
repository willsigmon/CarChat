import Foundation
import KeychainAccess

actor KeychainManager {
    private let keychain: Keychain

    init(service: String = "com.willsigmon.carchat") {
        self.keychain = Keychain(service: service)
            .accessibility(.afterFirstUnlock)
    }

    func save(key: String, value: String) throws {
        try keychain.set(value, key: key)
    }

    func get(key: String) throws -> String? {
        try keychain.get(key)
    }

    func delete(key: String) throws {
        try keychain.remove(key)
    }

    func saveAPIKey(for provider: AIProviderType, key: String) throws {
        try save(key: provider.keychainKey, value: key)
    }

    func getAPIKey(for provider: AIProviderType) throws -> String? {
        try get(key: provider.keychainKey)
    }

    func deleteAPIKey(for provider: AIProviderType) throws {
        try delete(key: provider.keychainKey)
    }

    func hasAPIKey(for provider: AIProviderType) throws -> Bool {
        guard let key = try get(key: provider.keychainKey) else {
            return false
        }
        return !key.isEmpty
    }

    // MARK: - ElevenLabs TTS Key

    private static let elevenLabsKey = "carchat.apikey.elevenlabs"

    func saveElevenLabsKey(_ key: String) throws {
        try save(key: Self.elevenLabsKey, value: key)
    }

    func getElevenLabsKey() throws -> String? {
        try get(key: Self.elevenLabsKey)
    }

    func deleteElevenLabsKey() throws {
        try delete(key: Self.elevenLabsKey)
    }

    func hasElevenLabsKey() throws -> Bool {
        guard let key = try get(key: Self.elevenLabsKey) else {
            return false
        }
        return !key.isEmpty
    }
}
