import SwiftUI

struct AmazonPollyVoiceSettingsSection: View {
    @Environment(AppServices.self) private var appServices

    @State private var amazonPollyAccessKey = ""
    @State private var amazonPollySecretKey = ""
    @State private var hasAmazonPollyKey = false
    @State private var isEditingAmazonPollyKey = false
    @State private var selectedAmazonPollyVoiceID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("AMAZON POLLY SETUP")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasAmazonPollyKey {
                        StatusBadge(text: "Connected", color: CarChatTheme.Colors.success)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.xs)

                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            LayeredFeatureIcon(
                                systemName: "key.fill",
                                color: CarChatTheme.Colors.accentGradientStart,
                                accentShape: .none
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AWS Credentials")
                                    .font(CarChatTheme.Typography.headline)
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                Text(hasAmazonPollyKey
                                     ? "Your keys are securely stored in Keychain"
                                     : "Requires AWS access key + secret key")
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }

                            Spacer()
                        }

                        if isEditingAmazonPollyKey {
                            VStack(spacing: CarChatTheme.Spacing.xs) {
                                HStack(spacing: CarChatTheme.Spacing.xs) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                                    SecureField("Access Key ID", text: $amazonPollyAccessKey)
                                        .font(CarChatTheme.Typography.body)
                                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(CarChatTheme.Colors.accentGradientStart)
                                }
                                .padding(CarChatTheme.Spacing.xs)
                                .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                                HStack(spacing: CarChatTheme.Spacing.xs) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                                    SecureField("Secret Access Key", text: $amazonPollySecretKey)
                                        .font(CarChatTheme.Typography.body)
                                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(CarChatTheme.Colors.accentGradientStart)
                                }
                                .padding(CarChatTheme.Spacing.xs)
                                .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                                Button("Save") {
                                    saveAmazonPollyKeys()
                                }
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, CarChatTheme.Spacing.sm)
                                .padding(.vertical, CarChatTheme.Spacing.xs)
                                .background(Capsule().fill(CarChatTheme.Gradients.accent))
                            }
                        } else {
                            Button(hasAmazonPollyKey ? "Update Keys" : "Add Keys") {
                                isEditingAmazonPollyKey = true
                            }
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                        }
                    }
                }
            }

            if hasAmazonPollyKey {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    Text("VOICE")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.xs)

                    ForEach(AmazonPollyVoiceCatalog.englishVoices) { voice in
                        SimpleVoiceRow(
                            name: voice.name,
                            detail: "\(voice.gender) \u{2022} \(voice.engine)",
                            isSelected: voice.id == selectedAmazonPollyVoiceID
                        ) {
                            selectedAmazonPollyVoiceID = voice.id
                            saveAmazonPollyVoice(voice.id)
                        }
                    }
                }
            }
        }
        .task { await loadState() }
    }

    // MARK: - Actions

    private func loadState() async {
        do {
            let accessKey = try await appServices.keychainManager.getAmazonPollyAccessKey()
            hasAmazonPollyKey = accessKey != nil && !(accessKey?.isEmpty ?? true)
        } catch {
            hasAmazonPollyKey = false
        }

        if let persona = fetchActivePersona(from: appServices) {
            selectedAmazonPollyVoiceID = persona.amazonPollyVoiceID
        }
    }

    private func saveAmazonPollyKeys() {
        Task {
            do {
                if amazonPollyAccessKey.isEmpty || amazonPollySecretKey.isEmpty {
                    try await appServices.keychainManager.deleteAmazonPollyKeys()
                    hasAmazonPollyKey = false
                } else {
                    try await appServices.keychainManager.saveAmazonPollyKeys(
                        accessKey: amazonPollyAccessKey,
                        secretKey: amazonPollySecretKey
                    )
                    hasAmazonPollyKey = true
                }
                isEditingAmazonPollyKey = false
                amazonPollyAccessKey = ""
                amazonPollySecretKey = ""
            } catch {
                // silently fail
            }
        }
    }

    private func saveAmazonPollyVoice(_ voiceID: String) {
        guard let persona = fetchActivePersona(from: appServices) else { return }
        persona.amazonPollyVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }
}
