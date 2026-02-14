import SwiftUI
import SwiftData

struct VoiceSettingsView: View {
    @Environment(AppServices.self) private var appServices
    @AppStorage("ttsEngine") private var ttsEngine = TTSEngineType.system.rawValue
    @AppStorage("elevenLabsModel") private var elevenLabsModel = ElevenLabsModel.flash.rawValue

    @State private var elevenLabsKey = ""
    @State private var hasElevenLabsKey = false
    @State private var isEditingKey = false
    @State private var voices: [ElevenLabsVoice] = []
    @State private var selectedVoiceID: String?
    @State private var isLoadingVoices = false
    @State private var voiceError: String?

    private var isElevenLabsSelected: Bool {
        ttsEngine == TTSEngineType.elevenLabs.rawValue
    }

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.md) {
                    ttsEngineSection
                    if isElevenLabsSelected {
                        elevenLabsKeySection
                        if hasElevenLabsKey {
                            elevenLabsModelSection
                            elevenLabsVoiceSection
                        }
                    }
                    vadSection
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.top, CarChatTheme.Spacing.sm)
            }
        }
        .navigationTitle("Voice")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadElevenLabsState() }
    }

    // MARK: - TTS Engine Picker

    @ViewBuilder
    private var ttsEngineSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("TEXT-TO-SPEECH ENGINE")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            ForEach(TTSEngineType.allCases) { engine in
                TTSEngineCard(
                    engine: engine,
                    isSelected: engine.rawValue == ttsEngine
                ) {
                    withAnimation(CarChatTheme.Animation.fast) {
                        ttsEngine = engine.rawValue
                    }
                }
            }
        }
    }

    // MARK: - ElevenLabs API Key

    @ViewBuilder
    private var elevenLabsKeySection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("ELEVENLABS API KEY")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                    HStack(spacing: CarChatTheme.Spacing.sm) {
                        LayeredFeatureIcon(
                            systemName: "key.fill",
                            color: CarChatTheme.Colors.accentGradientStart,
                            accentShape: .none
                        )

                        Text("API Key")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Spacer()

                        HStack(spacing: 4) {
                            Circle()
                                .fill(hasElevenLabsKey ? CarChatTheme.Colors.success : CarChatTheme.Colors.textTertiary)
                                .frame(width: 6, height: 6)

                            Text(hasElevenLabsKey ? "Configured" : "Not Set")
                                .font(CarChatTheme.Typography.micro)
                                .foregroundStyle(
                                    hasElevenLabsKey
                                        ? CarChatTheme.Colors.success
                                        : CarChatTheme.Colors.textTertiary
                                )
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.xs)
                        .padding(.vertical, CarChatTheme.Spacing.xxs)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
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
    }

    // MARK: - ElevenLabs Model

    @ViewBuilder
    private var elevenLabsModelSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("QUALITY / SPEED")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            ForEach(ElevenLabsModel.allCases) { model in
                Button {
                    withAnimation(CarChatTheme.Animation.fast) {
                        elevenLabsModel = model.rawValue
                    }
                } label: {
                    let isSelected = model.rawValue == elevenLabsModel
                    GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.displayName)
                                    .font(CarChatTheme.Typography.headline)
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                Text(model.subtitle)
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
                .sensoryFeedback(.selection, trigger: model.rawValue == elevenLabsModel)
            }
        }
    }

    // MARK: - ElevenLabs Voice Picker

    @ViewBuilder
    private var elevenLabsVoiceSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            HStack {
                Text("VOICE")
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)

                Spacer()

                if isLoadingVoices {
                    ProgressView()
                        .controlSize(.small)
                        .tint(CarChatTheme.Colors.accentGradientStart)
                } else if !voices.isEmpty {
                    Button {
                        Task { await fetchVoices() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, CarChatTheme.Spacing.xs)

            if let voiceError {
                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(CarChatTheme.Colors.error)
                        Text(voiceError)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textSecondary)
                    }
                }
            } else if voices.isEmpty && !isLoadingVoices {
                Button {
                    Task { await fetchVoices() }
                } label: {
                    GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                            Text("Load Available Voices")
                                .font(CarChatTheme.Typography.headline)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                            Spacer()
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                ForEach(voices) { voice in
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
            }
        }
    }

    // MARK: - VAD

    @ViewBuilder
    private var vadSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("VOICE ACTIVITY DETECTION")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: "waveform.badge.mic",
                        color: CarChatTheme.Colors.listening,
                        accentShape: .ring
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Detect Silence")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text("Automatically detects when you stop speaking.")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadElevenLabsState() async {
        do {
            let key = try await appServices.keychainManager.getElevenLabsKey()
            hasElevenLabsKey = key != nil && !(key?.isEmpty ?? true)
            if hasElevenLabsKey {
                // Load saved voice selection from persona
                if let persona = fetchActivePersona() {
                    selectedVoiceID = persona.elevenLabsVoiceID
                }
            }
        } catch {
            hasElevenLabsKey = false
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
        guard let persona = fetchActivePersona() else { return }
        persona.elevenLabsVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }

    private func fetchActivePersona() -> Persona? {
        let context = appServices.modelContainer.mainContext
        let descriptor = FetchDescriptor<Persona>(
            predicate: #Predicate { $0.isDefault == true }
        )
        return (try? context.fetch(descriptor))?.first
    }
}

// MARK: - TTS Engine Card

private struct TTSEngineCard: View {
    let engine: TTSEngineType
    let isSelected: Bool
    let action: () -> Void

    private var engineIcon: String {
        switch engine {
        case .system: "speaker.wave.2.fill"
        case .elevenLabs: "waveform.circle.fill"
        }
    }

    private var engineSubtitle: String {
        switch engine {
        case .system: "Built-in iOS voice synthesis"
        case .elevenLabs: "Ultra-realistic AI voices"
        }
    }

    var body: some View {
        Button(action: action) {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: engineIcon,
                        color: isSelected
                            ? CarChatTheme.Colors.accentGradientStart
                            : CarChatTheme.Colors.textTertiary,
                        accentShape: .none
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.displayName)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text(engineSubtitle)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
