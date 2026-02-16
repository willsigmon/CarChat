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

    // MARK: - Hume AI TTS Key

    private static let humeAIKey = "carchat.apikey.humeai"

    func saveHumeAIKey(_ key: String) throws {
        try save(key: Self.humeAIKey, value: key)
    }

    func getHumeAIKey() throws -> String? {
        try get(key: Self.humeAIKey)
    }

    func deleteHumeAIKey() throws {
        try delete(key: Self.humeAIKey)
    }

    func hasHumeAIKey() throws -> Bool {
        guard let key = try get(key: Self.humeAIKey) else {
            return false
        }
        return !key.isEmpty
    }

    // MARK: - Google Cloud TTS Key

    private static let googleCloudKey = "carchat.apikey.googlecloud"

    func saveGoogleCloudKey(_ key: String) throws {
        try save(key: Self.googleCloudKey, value: key)
    }

    func getGoogleCloudKey() throws -> String? {
        try get(key: Self.googleCloudKey)
    }

    func deleteGoogleCloudKey() throws {
        try delete(key: Self.googleCloudKey)
    }

    func hasGoogleCloudKey() throws -> Bool {
        guard let key = try get(key: Self.googleCloudKey) else { return false }
        return !key.isEmpty
    }

    // MARK: - Cartesia TTS Key

    private static let cartesiaKey = "carchat.apikey.cartesia"

    func saveCartesiaKey(_ key: String) throws {
        try save(key: Self.cartesiaKey, value: key)
    }

    func getCartesiaKey() throws -> String? {
        try get(key: Self.cartesiaKey)
    }

    func deleteCartesiaKey() throws {
        try delete(key: Self.cartesiaKey)
    }

    func hasCartesiaKey() throws -> Bool {
        guard let key = try get(key: Self.cartesiaKey) else { return false }
        return !key.isEmpty
    }

    // MARK: - Amazon Polly Keys (access key + secret key)

    private static let amazonPollyAccessKey = "carchat.apikey.polly.access"
    private static let amazonPollySecretKey = "carchat.apikey.polly.secret"

    func saveAmazonPollyKeys(accessKey: String, secretKey: String) throws {
        try save(key: Self.amazonPollyAccessKey, value: accessKey)
        try save(key: Self.amazonPollySecretKey, value: secretKey)
    }

    func getAmazonPollyAccessKey() throws -> String? {
        try get(key: Self.amazonPollyAccessKey)
    }

    func getAmazonPollySecretKey() throws -> String? {
        try get(key: Self.amazonPollySecretKey)
    }

    func deleteAmazonPollyKeys() throws {
        try delete(key: Self.amazonPollyAccessKey)
        try delete(key: Self.amazonPollySecretKey)
    }

    func hasAmazonPollyKeys() throws -> Bool {
        guard let access = try get(key: Self.amazonPollyAccessKey),
              let secret = try get(key: Self.amazonPollySecretKey) else { return false }
        return !access.isEmpty && !secret.isEmpty
    }

    // MARK: - Deepgram TTS Key

    private static let deepgramKey = "carchat.apikey.deepgram"

    func saveDeepgramKey(_ key: String) throws {
        try save(key: Self.deepgramKey, value: key)
    }

    func getDeepgramKey() throws -> String? {
        try get(key: Self.deepgramKey)
    }

    func deleteDeepgramKey() throws {
        try delete(key: Self.deepgramKey)
    }

    func hasDeepgramKey() throws -> Bool {
        guard let key = try get(key: Self.deepgramKey) else { return false }
        return !key.isEmpty
    }
}
