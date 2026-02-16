import AVFoundation
import SwiftUI
import SwiftData

struct VoiceSettingsView: View {
    @Environment(AppServices.self) private var appServices
    @AppStorage("ttsEngine") private var ttsEngine = TTSEngineType.system.rawValue
    @AppStorage("elevenLabsModel") private var elevenLabsModel = ElevenLabsModel.flash.rawValue
    @AppStorage("openAITTSModel") private var openAITTSModel = OpenAITTSModel.tts1.rawValue
    @AppStorage("audioOutputMode") private var audioOutputMode = AudioOutputMode.defaultMode.rawValue
    @AppStorage("systemTTSSpeechRate") private var speechRate: Double = 0.5
    @AppStorage("systemTTSPitch") private var pitchMultiplier: Double = 1.0

    // ElevenLabs state
    @State private var elevenLabsKey = ""
    @State private var hasElevenLabsKey = false
    @State private var isEditingKey = false
    @State private var voices: [ElevenLabsVoice] = []
    @State private var selectedVoiceID: String?
    @State private var isLoadingVoices = false
    @State private var voiceError: String?

    // OpenAI TTS state
    @State private var hasOpenAIKey = false
    @State private var selectedOpenAIVoice: String?

    // Hume AI state
    @State private var humeAIKey = ""
    @State private var hasHumeAIKey = false
    @State private var isEditingHumeKey = false
    @State private var humeVoices: [HumeAIVoice] = []
    @State private var selectedHumeVoiceID: String?
    @State private var isLoadingHumeVoices = false
    @State private var humeVoiceError: String?

    // Google Cloud TTS state
    @State private var googleCloudKey = ""
    @State private var hasGoogleCloudKey = false
    @State private var isEditingGoogleCloudKey = false
    @State private var googleCloudVoices: [GoogleCloudVoice] = []
    @State private var selectedGoogleCloudVoiceID: String?
    @State private var isLoadingGoogleCloudVoices = false
    @State private var googleCloudVoiceError: String?

    // Cartesia state
    @State private var cartesiaKey = ""
    @State private var hasCartesiaKey = false
    @State private var isEditingCartesiaKey = false
    @State private var cartesiaVoices: [CartesiaVoice] = []
    @State private var selectedCartesiaVoiceID: String?
    @State private var isLoadingCartesiaVoices = false
    @State private var cartesiaVoiceError: String?

    // Amazon Polly state
    @State private var amazonPollyAccessKey = ""
    @State private var amazonPollySecretKey = ""
    @State private var hasAmazonPollyKey = false
    @State private var isEditingAmazonPollyKey = false
    @State private var selectedAmazonPollyVoiceID: String?

    // Deepgram state
    @State private var deepgramKey = ""
    @State private var hasDeepgramKey = false
    @State private var isEditingDeepgramKey = false
    @State private var selectedDeepgramVoiceID: String?

    // Shared state
    @State private var isTesting = false
    @State private var testDiagnostic = ""
    @State private var testSynthesizer: AVSpeechSynthesizer?
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    @State private var selectedSystemVoiceID: String?

    private var selectedEngine: TTSEngineType {
        TTSEngineType(rawValue: ttsEngine) ?? .system
    }

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.lg) {
                    testVoiceSection
                    ttsEngineSection

                    switch selectedEngine {
                    case .system:
                        systemVoiceSection
                    case .openAI:
                        openAISection
                    case .elevenLabs:
                        elevenLabsSection
                    case .humeAI:
                        humeAISection
                    case .googleCloud:
                        googleCloudSection
                    case .cartesia:
                        cartesiaSection
                    case .amazonPolly:
                        amazonPollySection
                    case .deepgram:
                        deepgramSection
                    }

                    audioOutputSection
                    vadSection
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.top, CarChatTheme.Spacing.sm)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
            }
        }
        .navigationTitle("Voice & Audio")
        .task { await loadState() }
    }

    // MARK: - Test Voice

    @ViewBuilder
    private var testVoiceSection: some View {
        Button {
            testVoice()
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.lg, padding: CarChatTheme.Spacing.md) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                isTesting
                                    ? CarChatTheme.Colors.speaking.opacity(0.2)
                                    : CarChatTheme.Colors.accentGradientStart.opacity(0.15)
                            )
                            .frame(width: 44, height: 44)

                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(CarChatTheme.Colors.speaking)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isTesting ? "Speaking..." : "Test Voice")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text(testDiagnostic.isEmpty
                             ? "Hear how the current voice sounds"
                             : testDiagnostic)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(
                                testDiagnostic.isEmpty
                                    ? CarChatTheme.Colors.textTertiary
                                    : CarChatTheme.Colors.speaking
                            )
                    }

                    Spacer()

                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            isTesting
                                ? CarChatTheme.Colors.speaking
                                : CarChatTheme.Colors.textTertiary
                        )
                        .symbolEffect(.variableColor.iterative, isActive: isTesting)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isTesting)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isTesting)
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

    // MARK: - System Voice Configuration

    @ViewBuilder
    private var systemVoiceSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("SYSTEM VOICE")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            // Voice picker
            if availableVoices.isEmpty {
                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                    HStack(spacing: CarChatTheme.Spacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(CarChatTheme.Colors.accentGradientStart)
                        Text("Loading voices...")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        Spacer()
                    }
                }
            } else {
                // Default option
                voiceRow(
                    name: "Default",
                    detail: "System default English voice",
                    quality: nil,
                    isSelected: selectedSystemVoiceID == nil
                ) {
                    withAnimation(CarChatTheme.Animation.fast) {
                        selectedSystemVoiceID = nil
                        saveSystemVoice(nil)
                    }
                }

                ForEach(availableVoices, id: \.identifier) { voice in
                    let isSelected = voice.identifier == selectedSystemVoiceID
                    voiceRow(
                        name: voice.name,
                        detail: voiceQualityLabel(voice.quality),
                        quality: voice.quality,
                        isSelected: isSelected
                    ) {
                        withAnimation(CarChatTheme.Animation.fast) {
                            selectedSystemVoiceID = voice.identifier
                            saveSystemVoice(voice.identifier)
                        }
                    }
                }
            }

            // Speech Rate
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "gauge.with.needle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CarChatTheme.Colors.speaking)

                        Text("Speech Rate")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Spacer()

                        Text(speechRateLabel)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            .monospacedDigit()
                    }

                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Image(systemName: "tortoise.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)

                        Slider(value: $speechRate, in: 0.3...0.65, step: 0.05)
                            .tint(CarChatTheme.Colors.speaking)

                        Image(systemName: "hare.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }
                }
            }

            // Pitch
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CarChatTheme.Colors.listening)

                        Text("Pitch")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Spacer()

                        Text(pitchLabel)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            .monospacedDigit()
                    }

                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Text("Low")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)

                        Slider(value: $pitchMultiplier, in: 0.75...1.5, step: 0.05)
                            .tint(CarChatTheme.Colors.listening)

                        Text("High")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - ElevenLabs Configuration

    @ViewBuilder
    private var elevenLabsSection: some View {
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
                            elevenLabsVoiceRow(voice)
                        }
                    }
                }
            }
        }
    }

    // MARK: - OpenAI TTS Configuration

    @ViewBuilder
    private var openAISection: some View {
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
    }

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

    // MARK: - Hume AI Configuration

    @ViewBuilder
    private var humeAISection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            // API Key
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("HUME AI SETUP")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasHumeAIKey {
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

                                Text(hasHumeAIKey
                                     ? "Your key is securely stored in Keychain"
                                     : "Get one at platform.hume.ai")
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }

                            Spacer()
                        }

                        if isEditingHumeKey {
                            HStack(spacing: CarChatTheme.Spacing.xs) {
                                HStack(spacing: CarChatTheme.Spacing.xs) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                                    SecureField("hume-...", text: $humeAIKey)
                                        .font(CarChatTheme.Typography.body)
                                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(CarChatTheme.Colors.accentGradientStart)
                                }
                                .padding(CarChatTheme.Spacing.xs)
                                .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                                Button("Save") {
                                    saveHumeAIKey()
                                }
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, CarChatTheme.Spacing.sm)
                                .padding(.vertical, CarChatTheme.Spacing.xs)
                                .background(Capsule().fill(CarChatTheme.Gradients.accent))
                            }
                        } else {
                            Button(hasHumeAIKey ? "Update Key" : "Add Key") {
                                isEditingHumeKey = true
                            }
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                        }
                    }
                }
            }

            // Voice picker (only when key is set)
            if hasHumeAIKey {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    HStack {
                        Text("VOICE")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)

                        Spacer()

                        if isLoadingHumeVoices {
                            ProgressView()
                                .controlSize(.small)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        } else if !humeVoices.isEmpty {
                            Button {
                                Task { await fetchHumeVoices() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xs)

                    if let humeVoiceError {
                        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                            HStack(spacing: CarChatTheme.Spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(CarChatTheme.Colors.error)
                                Text(humeVoiceError)
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
                            }
                        }
                    } else if humeVoices.isEmpty && !isLoadingHumeVoices {
                        Button {
                            Task { await fetchHumeVoices() }
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
                        ForEach(humeVoices) { voice in
                            humeVoiceRow(voice)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func humeVoiceRow(_ voice: HumeAIVoice) -> some View {
        let isSelected = voice.name == selectedHumeVoiceID
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                selectedHumeVoiceID = voice.name
                saveHumeVoice(voice.name)
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

                        if !voice.description.isEmpty {
                            Text(voice.description)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                .lineLimit(1)
                        }
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

    // MARK: - Google Cloud TTS Configuration

    @ViewBuilder
    private var googleCloudSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("GOOGLE CLOUD TTS")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasGoogleCloudKey {
                        StatusBadge(text: "Connected", color: CarChatTheme.Colors.success)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.xs)

                byokKeyCard(
                    hasKey: hasGoogleCloudKey,
                    isEditing: $isEditingGoogleCloudKey,
                    keyText: $googleCloudKey,
                    placeholder: "AIza...",
                    providerURL: "console.cloud.google.com",
                    onSave: saveGoogleCloudKey
                )
            }

            if hasGoogleCloudKey {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    HStack {
                        Text("VOICE")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)

                        Spacer()

                        if isLoadingGoogleCloudVoices {
                            ProgressView()
                                .controlSize(.small)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        } else if !googleCloudVoices.isEmpty {
                            Button {
                                Task { await fetchGoogleCloudVoices() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xs)

                    if let googleCloudVoiceError {
                        voiceErrorCard(googleCloudVoiceError)
                    } else if googleCloudVoices.isEmpty && !isLoadingGoogleCloudVoices {
                        loadVoicesButton { Task { await fetchGoogleCloudVoices() } }
                    } else {
                        ForEach(googleCloudVoices) { voice in
                            simpleVoiceRow(
                                name: voice.name,
                                detail: voice.languageCodes.first ?? "",
                                isSelected: voice.name == selectedGoogleCloudVoiceID
                            ) {
                                selectedGoogleCloudVoiceID = voice.name
                                saveGoogleCloudVoice(voice.name)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cartesia Configuration

    @ViewBuilder
    private var cartesiaSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("CARTESIA SETUP")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasCartesiaKey {
                        StatusBadge(text: "Connected", color: CarChatTheme.Colors.success)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.xs)

                byokKeyCard(
                    hasKey: hasCartesiaKey,
                    isEditing: $isEditingCartesiaKey,
                    keyText: $cartesiaKey,
                    placeholder: "sk-...",
                    providerURL: "play.cartesia.ai",
                    onSave: saveCartesiaKey
                )
            }

            if hasCartesiaKey {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    HStack {
                        Text("VOICE")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)

                        Spacer()

                        if isLoadingCartesiaVoices {
                            ProgressView()
                                .controlSize(.small)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        } else if !cartesiaVoices.isEmpty {
                            Button {
                                Task { await fetchCartesiaVoices() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xs)

                    if let cartesiaVoiceError {
                        voiceErrorCard(cartesiaVoiceError)
                    } else if cartesiaVoices.isEmpty && !isLoadingCartesiaVoices {
                        loadVoicesButton { Task { await fetchCartesiaVoices() } }
                    } else {
                        ForEach(cartesiaVoices) { voice in
                            simpleVoiceRow(
                                name: voice.name,
                                detail: voice.description,
                                isSelected: voice.id == selectedCartesiaVoiceID
                            ) {
                                selectedCartesiaVoiceID = voice.id
                                saveCartesiaVoice(voice.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Amazon Polly Configuration

    @ViewBuilder
    private var amazonPollySection: some View {
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
                        simpleVoiceRow(
                            name: voice.name,
                            detail: "\(voice.gender) • \(voice.engine)",
                            isSelected: voice.id == selectedAmazonPollyVoiceID
                        ) {
                            selectedAmazonPollyVoiceID = voice.id
                            saveAmazonPollyVoice(voice.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Deepgram Configuration

    @ViewBuilder
    private var deepgramSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("DEEPGRAM SETUP")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    if hasDeepgramKey {
                        StatusBadge(text: "Connected", color: CarChatTheme.Colors.success)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.xs)

                byokKeyCard(
                    hasKey: hasDeepgramKey,
                    isEditing: $isEditingDeepgramKey,
                    keyText: $deepgramKey,
                    placeholder: "dg-...",
                    providerURL: "console.deepgram.com",
                    onSave: saveDeepgramKey
                )
            }

            if hasDeepgramKey {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                    Text("VOICE")
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.xs)

                    ForEach(DeepgramVoiceCatalog.aura2Voices) { voice in
                        simpleVoiceRow(
                            name: voice.name,
                            detail: voice.description,
                            isSelected: voice.id == selectedDeepgramVoiceID
                        ) {
                            selectedDeepgramVoiceID = voice.id
                            saveDeepgramVoice(voice.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared Builders

    @ViewBuilder
    private func byokKeyCard(
        hasKey: Bool,
        isEditing: Binding<Bool>,
        keyText: Binding<String>,
        placeholder: String,
        providerURL: String,
        onSave: @escaping () -> Void
    ) -> some View {
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

                        Text(hasKey
                             ? "Your key is securely stored in Keychain"
                             : "Get one at \(providerURL)")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()
                }

                if isEditing.wrappedValue {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        HStack(spacing: CarChatTheme.Spacing.xs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)

                            SecureField(placeholder, text: keyText)
                                .font(CarChatTheme.Typography.body)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        }
                        .padding(CarChatTheme.Spacing.xs)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                        Button("Save") {
                            onSave()
                        }
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, CarChatTheme.Spacing.sm)
                        .padding(.vertical, CarChatTheme.Spacing.xs)
                        .background(Capsule().fill(CarChatTheme.Gradients.accent))
                    }
                } else {
                    Button(hasKey ? "Update Key" : "Add Key") {
                        isEditing.wrappedValue = true
                    }
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                }
            }
        }
    }

    @ViewBuilder
    private func voiceErrorCard(_ error: String) -> some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
            HStack(spacing: CarChatTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CarChatTheme.Colors.error)
                Text(error)
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func loadVoicesButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
    }

    @ViewBuilder
    private func simpleVoiceRow(
        name: String,
        detail: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                action()
            }
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(CarChatTheme.Colors.speaking.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(CarChatTheme.Colors.speaking)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        if !detail.isEmpty {
                            Text(detail)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                .lineLimit(1)
                        }
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

    // MARK: - Audio Output

    @ViewBuilder
    private var audioOutputSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("AUDIO OUTPUT")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            ForEach(AudioOutputMode.allCases) { mode in
                let isSelected = mode.rawValue == audioOutputMode
                Button {
                    withAnimation(CarChatTheme.Animation.fast) {
                        audioOutputMode = mode.rawValue
                        AudioSessionManager.shared.setPreferredOutputMode(mode)
                    }
                } label: {
                    AudioOutputCard(mode: mode, isSelected: isSelected)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: isSelected)
            }

            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxxs) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        Text("Current route: \(AudioSessionManager.shared.currentOutputRouteName)")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textSecondary)
                    }
                    Text(AudioSessionManager.shared.currentRouteSummary)
                        .font(CarChatTheme.Typography.micro)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - VAD

    @ViewBuilder
    private var vadSection: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text("ADVANCED")
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

                        Text("Automatically ends recording when you stop speaking.")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func voiceRow(
        name: String,
        detail: String,
        quality: AVSpeechSynthesisVoiceQuality?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text(detail)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()

                    if let quality {
                        Text(qualityBadgeText(quality))
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(qualityBadgeColor(quality))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(qualityBadgeColor(quality).opacity(0.12))
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

    private var speechRateLabel: String {
        if abs(speechRate - 0.5) < 0.01 { return "Normal" }
        if speechRate < 0.4 { return "Slow" }
        if speechRate < 0.5 { return "Relaxed" }
        if speechRate < 0.6 { return "Brisk" }
        return "Fast"
    }

    private var pitchLabel: String {
        if abs(pitchMultiplier - 1.0) < 0.01 { return "Normal" }
        if pitchMultiplier < 1.0 { return "Deeper" }
        return "Higher"
    }

    private func voiceQualityLabel(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: "Premium — most natural"
        case .enhanced: "Enhanced — higher quality"
        default: "Standard"
        }
    }

    private func qualityBadgeText(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: "Premium"
        case .enhanced: "Enhanced"
        default: "Standard"
        }
    }

    private func qualityBadgeColor(_ quality: AVSpeechSynthesisVoiceQuality) -> Color {
        switch quality {
        case .premium: CarChatTheme.Colors.accentGradientStart
        case .enhanced: CarChatTheme.Colors.success
        default: CarChatTheme.Colors.textTertiary
        }
    }

    private func modelIcon(_ model: ElevenLabsModel) -> String {
        switch model {
        case .flash: "bolt.fill"
        case .turbo: "gauge.with.dots.needle.67percent"
        case .multilingualV2: "globe"
        case .englishV1: "textformat"
        }
    }

    // MARK: - Actions

    private func testVoice() {
        guard !isTesting else { return }
        isTesting = true
        testDiagnostic = ""
        Haptics.tap()

        let testText = "Hello! This is a voice test. How does this sound?"

        Task {
            let engine: TTSEngineProtocol

            switch selectedEngine {
            case .system:
                testDiagnostic = "Testing System voice..."
                let tts = SystemTTS()
                if let voiceId = selectedSystemVoiceID {
                    tts.setVoice(identifier: voiceId)
                }
                engine = tts

            case .openAI:
                testDiagnostic = "Testing OpenAI voice..."
                if let key = try? await appServices.keychainManager.getAPIKey(for: .openAI),
                   !key.isEmpty {
                    let modelRaw = openAITTSModel
                    let model = OpenAITTSModel(rawValue: modelRaw) ?? .tts1
                    let tts = OpenAITTS(apiKey: key, model: model)
                    if let voice = selectedOpenAIVoice {
                        tts.setVoice(voice)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No OpenAI key — falling back to System"
                    engine = SystemTTS()
                }

            case .elevenLabs:
                testDiagnostic = "Testing ElevenLabs voice..."
                if let key = try? await appServices.keychainManager.getElevenLabsKey(),
                   !key.isEmpty {
                    let modelRaw = elevenLabsModel
                    let model = ElevenLabsModel(rawValue: modelRaw) ?? .flash
                    let tts = ElevenLabsTTS(apiKey: key, model: model)
                    if let voiceId = selectedVoiceID {
                        tts.setVoice(id: voiceId)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No ElevenLabs key — falling back to System"
                    engine = SystemTTS()
                }

            case .humeAI:
                testDiagnostic = "Testing Hume AI voice..."
                if let key = try? await appServices.keychainManager.getHumeAIKey(),
                   !key.isEmpty {
                    let tts = HumeAITTS(apiKey: key)
                    if let voiceId = selectedHumeVoiceID {
                        tts.setVoice(id: voiceId)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No Hume AI key — falling back to System"
                    engine = SystemTTS()
                }

            case .googleCloud:
                testDiagnostic = "Testing Google Cloud voice..."
                if let key = try? await appServices.keychainManager.getGoogleCloudKey(),
                   !key.isEmpty {
                    let tts = GoogleCloudTTS(apiKey: key)
                    if let voiceId = selectedGoogleCloudVoiceID {
                        tts.setVoice(id: voiceId)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No Google Cloud key — falling back to System"
                    engine = SystemTTS()
                }

            case .cartesia:
                testDiagnostic = "Testing Cartesia voice..."
                if let key = try? await appServices.keychainManager.getCartesiaKey(),
                   !key.isEmpty {
                    let tts = CartesiaTTS(apiKey: key)
                    if let voiceId = selectedCartesiaVoiceID {
                        tts.setVoice(id: voiceId)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No Cartesia key — falling back to System"
                    engine = SystemTTS()
                }

            case .amazonPolly:
                testDiagnostic = "Testing Amazon Polly voice..."
                if let accessKey = try? await appServices.keychainManager.getAmazonPollyAccessKey(),
                   let secretKey = try? await appServices.keychainManager.getAmazonPollySecretKey(),
                   !accessKey.isEmpty, !secretKey.isEmpty {
                    let tts = AmazonPollyTTS(accessKey: accessKey, secretKey: secretKey)
                    if let voiceId = selectedAmazonPollyVoiceID {
                        tts.setVoice(id: voiceId)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No Amazon Polly keys — falling back to System"
                    engine = SystemTTS()
                }

            case .deepgram:
                testDiagnostic = "Testing Deepgram voice..."
                if let key = try? await appServices.keychainManager.getDeepgramKey(),
                   !key.isEmpty {
                    let tts = DeepgramTTS(apiKey: key)
                    if let voiceId = selectedDeepgramVoiceID {
                        tts.setVoice(id: voiceId)
                    }
                    engine = tts
                } else {
                    testDiagnostic = "No Deepgram key — falling back to System"
                    engine = SystemTTS()
                }
            }

            await engine.speak(testText)
            testDiagnostic = ""
            isTesting = false
        }
    }

    private func loadState() async {
        // Load system voices
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        availableVoices = allVoices
            .filter { $0.language.hasPrefix("en") }
            .sorted { lhs, rhs in
                if lhs.quality != rhs.quality {
                    return lhs.quality.rawValue > rhs.quality.rawValue
                }
                return lhs.name < rhs.name
            }

        // Load persona selections
        if let persona = fetchActivePersona() {
            selectedSystemVoiceID = persona.systemTTSVoice
            selectedVoiceID = persona.elevenLabsVoiceID
            selectedOpenAIVoice = persona.openAITTSVoice ?? OpenAITTSVoice.nova.rawValue
            selectedHumeVoiceID = persona.humeAIVoiceID
        }

        // Load ElevenLabs state
        do {
            let key = try await appServices.keychainManager.getElevenLabsKey()
            hasElevenLabsKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasElevenLabsKey = false
        }

        // Load OpenAI key state
        do {
            let key = try await appServices.keychainManager.getAPIKey(for: .openAI)
            hasOpenAIKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasOpenAIKey = false
        }

        // Load Hume AI state
        do {
            let key = try await appServices.keychainManager.getHumeAIKey()
            hasHumeAIKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasHumeAIKey = false
        }

        // Load Google Cloud state
        do {
            let key = try await appServices.keychainManager.getGoogleCloudKey()
            hasGoogleCloudKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasGoogleCloudKey = false
        }

        // Load Cartesia state
        do {
            let key = try await appServices.keychainManager.getCartesiaKey()
            hasCartesiaKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasCartesiaKey = false
        }

        // Load Amazon Polly state
        do {
            let accessKey = try await appServices.keychainManager.getAmazonPollyAccessKey()
            hasAmazonPollyKey = accessKey != nil && !(accessKey?.isEmpty ?? true)
        } catch {
            hasAmazonPollyKey = false
        }

        // Load Deepgram state
        do {
            let key = try await appServices.keychainManager.getDeepgramKey()
            hasDeepgramKey = key != nil && !(key?.isEmpty ?? true)
        } catch {
            hasDeepgramKey = false
        }

        // Load new engine persona selections
        if let persona = fetchActivePersona() {
            selectedGoogleCloudVoiceID = persona.googleCloudVoiceID
            selectedCartesiaVoiceID = persona.cartesiaVoiceID
            selectedAmazonPollyVoiceID = persona.amazonPollyVoiceID
            selectedDeepgramVoiceID = persona.deepgramVoiceID
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

    private func saveSystemVoice(_ identifier: String?) {
        guard let persona = fetchActivePersona() else { return }
        persona.systemTTSVoice = identifier
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - OpenAI TTS Actions

    private func saveOpenAIVoice(_ voiceName: String) {
        guard let persona = fetchActivePersona() else { return }
        persona.openAITTSVoice = voiceName
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - Hume AI Actions

    private func saveHumeAIKey() {
        Task {
            do {
                if humeAIKey.isEmpty {
                    try await appServices.keychainManager.deleteHumeAIKey()
                    hasHumeAIKey = false
                } else {
                    try await appServices.keychainManager.saveHumeAIKey(humeAIKey)
                    hasHumeAIKey = true
                }
                isEditingHumeKey = false
                humeAIKey = ""
                humeVoices = []
            } catch {
                humeVoiceError = error.localizedDescription
            }
        }
    }

    private func fetchHumeVoices() async {
        isLoadingHumeVoices = true
        humeVoiceError = nil

        do {
            guard let key = try await appServices.keychainManager.getHumeAIKey(),
                  !key.isEmpty else {
                humeVoiceError = "API key not configured"
                isLoadingHumeVoices = false
                return
            }

            let manager = HumeAIVoiceManager()
            humeVoices = try await manager.voices(apiKey: key)
        } catch let error as HumeAIError {
            humeVoiceError = error.errorDescription
        } catch {
            humeVoiceError = error.localizedDescription
        }

        isLoadingHumeVoices = false
    }

    private func saveHumeVoice(_ voiceName: String) {
        guard let persona = fetchActivePersona() else { return }
        persona.humeAIVoiceID = voiceName
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - Google Cloud Actions

    private func saveGoogleCloudKey() {
        Task {
            do {
                if googleCloudKey.isEmpty {
                    try await appServices.keychainManager.deleteGoogleCloudKey()
                    hasGoogleCloudKey = false
                } else {
                    try await appServices.keychainManager.saveGoogleCloudKey(googleCloudKey)
                    hasGoogleCloudKey = true
                }
                isEditingGoogleCloudKey = false
                googleCloudKey = ""
                googleCloudVoices = []
            } catch {
                googleCloudVoiceError = error.localizedDescription
            }
        }
    }

    private func fetchGoogleCloudVoices() async {
        isLoadingGoogleCloudVoices = true
        googleCloudVoiceError = nil

        do {
            guard let key = try await appServices.keychainManager.getGoogleCloudKey(),
                  !key.isEmpty else {
                googleCloudVoiceError = "API key not configured"
                isLoadingGoogleCloudVoices = false
                return
            }

            let manager = GoogleCloudVoiceManager()
            googleCloudVoices = try await manager.voices(apiKey: key)
        } catch let error as GoogleCloudTTSError {
            googleCloudVoiceError = error.errorDescription
        } catch {
            googleCloudVoiceError = error.localizedDescription
        }

        isLoadingGoogleCloudVoices = false
    }

    private func saveGoogleCloudVoice(_ voiceID: String) {
        guard let persona = fetchActivePersona() else { return }
        persona.googleCloudVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - Cartesia Actions

    private func saveCartesiaKey() {
        Task {
            do {
                if cartesiaKey.isEmpty {
                    try await appServices.keychainManager.deleteCartesiaKey()
                    hasCartesiaKey = false
                } else {
                    try await appServices.keychainManager.saveCartesiaKey(cartesiaKey)
                    hasCartesiaKey = true
                }
                isEditingCartesiaKey = false
                cartesiaKey = ""
                cartesiaVoices = []
            } catch {
                cartesiaVoiceError = error.localizedDescription
            }
        }
    }

    private func fetchCartesiaVoices() async {
        isLoadingCartesiaVoices = true
        cartesiaVoiceError = nil

        do {
            guard let key = try await appServices.keychainManager.getCartesiaKey(),
                  !key.isEmpty else {
                cartesiaVoiceError = "API key not configured"
                isLoadingCartesiaVoices = false
                return
            }

            let manager = CartesiaVoiceManager()
            cartesiaVoices = try await manager.voices(apiKey: key)
        } catch let error as CartesiaTTSError {
            cartesiaVoiceError = error.errorDescription
        } catch {
            cartesiaVoiceError = error.localizedDescription
        }

        isLoadingCartesiaVoices = false
    }

    private func saveCartesiaVoice(_ voiceID: String) {
        guard let persona = fetchActivePersona() else { return }
        persona.cartesiaVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - Amazon Polly Actions

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
        guard let persona = fetchActivePersona() else { return }
        persona.amazonPollyVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - Deepgram Actions

    private func saveDeepgramKey() {
        Task {
            do {
                if deepgramKey.isEmpty {
                    try await appServices.keychainManager.deleteDeepgramKey()
                    hasDeepgramKey = false
                } else {
                    try await appServices.keychainManager.saveDeepgramKey(deepgramKey)
                    hasDeepgramKey = true
                }
                isEditingDeepgramKey = false
                deepgramKey = ""
            } catch {
                // silently fail
            }
        }
    }

    private func saveDeepgramVoice(_ voiceID: String) {
        guard let persona = fetchActivePersona() else { return }
        persona.deepgramVoiceID = voiceID
        try? appServices.modelContainer.mainContext.save()
    }

    // MARK: - Persona Lookup

    private func fetchActivePersona() -> Persona? {
        let context = appServices.modelContainer.mainContext
        let descriptor = FetchDescriptor<Persona>(
            predicate: #Predicate { $0.isDefault == true }
        )
        return (try? context.fetch(descriptor))?.first
    }
}

// MARK: - Audio Output Card

private struct AudioOutputCard: View {
    let mode: AudioOutputMode
    let isSelected: Bool

    private var icon: String {
        switch mode {
        case .automatic: "point.3.connected.trianglepath.dotted"
        case .speakerphone: "speaker.wave.3.fill"
        }
    }

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
            HStack(spacing: CarChatTheme.Spacing.sm) {
                LayeredFeatureIcon(
                    systemName: icon,
                    color: isSelected
                        ? CarChatTheme.Colors.accentGradientStart
                        : CarChatTheme.Colors.textTertiary,
                    accentShape: .none
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Text(mode.subtitle)
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
}

// MARK: - TTS Engine Card

private struct TTSEngineCard: View {
    let engine: TTSEngineType
    let isSelected: Bool
    let action: () -> Void

    private var engineIcon: String {
        switch engine {
        case .system: "speaker.wave.2.fill"
        case .openAI: "brain.head.profile.fill"
        case .elevenLabs: "waveform.circle.fill"
        case .humeAI: "heart.text.clipboard.fill"
        case .googleCloud: "cloud.fill"
        case .cartesia: "bolt.circle.fill"
        case .amazonPolly: "waveform.path"
        case .deepgram: "mic.badge.waveform"
        }
    }

    private var engineSubtitle: String {
        switch engine {
        case .system: "Built-in iOS voice synthesis — free, no setup"
        case .openAI: "Natural AI voices — uses your OpenAI key"
        case .elevenLabs: "Ultra-realistic AI voices — requires API key"
        case .humeAI: "Emotionally expressive voices — requires API key"
        case .googleCloud: "300+ voices across multiple tiers — BYOK"
        case .cartesia: "Ultra-low latency AI voices — BYOK"
        case .amazonPolly: "AWS neural voices — requires access + secret key"
        case .deepgram: "Aura-2 fast voices — BYOK"
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
