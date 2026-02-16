import SwiftUI

struct ElevenLabsVoiceSettingsSection: View {
    @Environment(AppServices.self) private var appServices
    @AppStorage("elevenLabsModel") private var elevenLabsModel = ElevenLabsModel.flash.rawValue

    @State private var elevenLabsKey = ""
    @State private var hasElevenLabsKey = false
    @State private var isEditingKey = false
    @State private var voices: [ElevenLabsVoice] = []
    @State private var selectedVoiceID: String?
    @State private var isLoadingVoices = false
    @State private var voiceError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            // API Key
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("ELEVENLABS SETUP")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasElevenLabsKey {
                        StatusBadge(
                            text: "Connected",
                            color: CarChatTheme.Colors.success
                        )
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
                                Text("API Key")
                                    .font(CarChatTheme.Typography.headline)
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                Text(hasElevenLabsKey
                                     ? "Your key is securely stored in Keychain"
                                     : "Get one free at elevenlabs.io")
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }

                            Spacer()
                        }

                        if isEditingKey {
                            HStack(spacing: CarChatTheme.Spacing.xs) {
                                HStack(spacing: CarChatTheme.Spacing.xs) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                                    SecureField("xi-...", text: $elevenLabsKey)
                                        .font(CarChatTheme.Typography.body)
                                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(CarChatTheme.Colors.accentGradientStart)
                                }
                                .padding(CarChatTheme.Spacing.xs)
                                .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                                Button("Save") {
                                    saveElevenLabsKey()
                                }
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, CarChatTheme.Spacing.sm)
                                .padding(.vertical, CarChatTheme.Spacing.xs)
                                .background(Capsule().fill(CarChatTheme.Gradients.accent))
                            }
                        } else {
                            Button(hasElevenLabsKey ? "Update Key" : "Add Key") {
                                isEditingKey = true
                            }
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                        }
                    }
                }
            }

            // Model picker (only when key is set)
            if hasElevenLabsKey {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    Text("MODEL")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.xs)

                    ForEach(ElevenLabsModel.allCases) { model in
                        elevenLabsModelRow(model)
                    }
                }

                // Voice picker
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    VoicePickerHeader(
                        isLoading: isLoadingVoices,
                        hasVoices: !voices.isEmpty,
                        onRefresh: { Task { await fetchVoices() } }
                    )

                    if let voiceError {
                        VoiceErrorCard(error: voiceError)
                    } else if voices.isEmpty && !isLoadingVoices {
                        LoadVoicesButton { Task { await fetchVoices() } }
                    } else {
                        ForEach(voices) { voice in
                            elevenLabsVoiceRow(voice)
                        }
                    }
                }
            }
        }
        .task { await loadState() }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func elevenLabsModelRow(_ model: ElevenLabsModel) -> some View {
        let isSelected = model.rawValue == elevenLabsModel
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                elevenLabsModel = model.rawValue
            }
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: modelIcon(model),
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
    private func elevenLabsVoiceRow(_ voice: ElevenLabsVoice) -> some View {
        let isSelected = voice.voiceId == selectedVoiceID
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                selectedVoiceID = voice.voiceId
                saveSelectedVoice(voice.voiceId)
            }
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(CarChatTheme.Colors.speaking.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(String(voice.name.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(CarChatTheme.Colors.speaking)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(voice.name)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        if !voice.subtitle.isEmpty {
                            Text(voice.subtitle)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Text(voice.categoryLabel)
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)

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

    // MARK: - Helpers

    private func modelIcon(_ model: ElevenLabsModel) -> String {
        switch model {
        case .flash: "bolt.fill"
        case .turbo: "gauge.with.dots.needle.67percent"
        case .multilingualV2: "globe"
        case .englishV1: "textformat"
        }
    }

    // MARK: - Actions

    private func loadState() async {
        do {
            let key = try await appServices.keychainManager.getElevenLabsKey()
            hasElevenLabsKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasElevenLabsKey = false
        }

        if let persona = fetchActivePersona(from: appServices) {
            selectedVoiceID = persona.elevenLabsVoiceID
        }
    }

    private func saveElevenLabsKey() {
        Task {
            do {
                if elevenLabsKey.isEmpty {
                    try await appServices.keychainManager.deleteElevenLabsKey()
                    hasElevenLabsKey = false
                } else {
                    try await appServices.keychainManager.saveElevenLabsKey(elevenLabsKey)
                    hasElevenLabsKey = true
                }
                isEditingKey = false
                elevenLabsKey = ""
                voices = []
            } catch {
                voiceError = error.localizedDescription
            }
        }
    }

    private func fetchVoices() async {
        isLoadingVoices = true
        voiceError = nil

        do {
            guard let key = try await appServices.keychainManager.getElevenLabsKey(),
                  !key.isEmpty else {
                voiceError = "API key not configured"
                isLoadingVoices = false
                return
            }

            let manager = ElevenLabsVoiceManager()
            voices = try await manager.voices(apiKey: key)
        } catch let error as ElevenLabsError {
            voiceError = error.errorDescription
        } catch {
            voiceError = error.localizedDescription
        }

        isLoadingVoices = false
    }

    private func saveSelectedVoice(_ voiceID: String) {
        guard let persona = fetchActivePersona(from: appServices) else { return }
        persona.elevenLabsVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }
}
