import SwiftUI

struct OpenAIVoiceSettingsSection: View {
    @Environment(AppServices.self) private var appServices
    @AppStorage("openAITTSModel") private var openAITTSModel = OpenAITTSModel.tts1.rawValue

    @State private var hasOpenAIKey = false
    @State private var selectedOpenAIVoice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            // Connection status
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("OPENAI TTS")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasOpenAIKey {
                        StatusBadge(
                            text: "Connected",
                            color: CarChatTheme.Colors.success
                        )
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.xs)

                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
                    HStack(spacing: CarChatTheme.Spacing.sm) {
                        LayeredFeatureIcon(
                            systemName: "brain.head.profile.fill",
                            color: CarChatTheme.Colors.accentGradientStart,
                            accentShape: .none
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("API Key")
                                .font(CarChatTheme.Typography.headline)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)

                            Text(hasOpenAIKey
                                 ? "Uses your existing OpenAI key from AI provider setup"
                                 : "Add an OpenAI key in AI Provider settings first")
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        }

                        Spacer()
                    }
                }
            }

            if hasOpenAIKey {
                // Model picker
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    Text("MODEL")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.xs)

                    ForEach(OpenAITTSModel.allCases) { model in
                        openAIModelRow(model)
                    }
                }

                // Voice picker
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    Text("VOICE")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.xs)

                    ForEach(OpenAITTSVoice.allCases) { voice in
                        openAIVoiceRow(voice)
                    }
                }
            }
        }
        .task { await loadState() }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func openAIModelRow(_ model: OpenAITTSModel) -> some View {
        let isSelected = model.rawValue == openAITTSModel
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                openAITTSModel = model.rawValue
            }
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: model == .tts1 ? "bolt.fill" : "sparkles",
                        color: isSelected
                            ? CarChatTheme.Colors.accentGradientStart
                            : CarChatTheme.Colors.textTertiary,
                        accentShape: .none
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text(model.subtitle)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()

                    if isSelected {
                        StatusBadge(
                            text: "Active",
                            color: CarChatTheme.Colors.success
                        )
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            isSelected
                                ? CarChatTheme.Colors.accentGradientStart
                                : CarChatTheme.Colors.textTertiary
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    @ViewBuilder
    private func openAIVoiceRow(_ voice: OpenAITTSVoice) -> some View {
        let isSelected = voice.rawValue == selectedOpenAIVoice
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                selectedOpenAIVoice = voice.rawValue
                saveOpenAIVoice(voice.rawValue)
            }
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(CarChatTheme.Colors.speaking.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(String(voice.displayName.prefix(1)))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(CarChatTheme.Colors.speaking)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(voice.displayName)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text(voice.description)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            isSelected
                                ? CarChatTheme.Colors.accentGradientStart
                                : CarChatTheme.Colors.textTertiary
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Actions

    private func loadState() async {
        do {
            let key = try await appServices.keychainManager.getAPIKey(for: .openAI)
            hasOpenAIKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasOpenAIKey = false
        }

        if let persona = fetchActivePersona(from: appServices) {
            selectedOpenAIVoice = persona.openAITTSVoice ?? OpenAITTSVoice.nova.rawValue
        }
    }

    private func saveOpenAIVoice(_ voiceName: String) {
        guard let persona = fetchActivePersona(from: appServices) else { return }
        persona.openAITTSVoice = voiceName
        try? appServices.modelContainer.mainContext.save()
    }
}
