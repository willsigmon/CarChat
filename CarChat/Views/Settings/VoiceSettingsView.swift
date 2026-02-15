import AVFoundation
import SwiftUI
import SwiftData

struct VoiceSettingsView: View {
    @Environment(AppServices.self) private var appServices
    @AppStorage("ttsEngine") private var ttsEngine = TTSEngineType.system.rawValue
    @AppStorage("elevenLabsModel") private var elevenLabsModel = ElevenLabsModel.flash.rawValue
    @AppStorage("audioOutputMode") private var audioOutputMode = AudioOutputMode.defaultMode.rawValue
    @AppStorage("systemTTSSpeechRate") private var speechRate: Double = 0.5
    @AppStorage("systemTTSPitch") private var pitchMultiplier: Double = 1.0

    @State private var elevenLabsKey = ""
    @State private var hasElevenLabsKey = false
    @State private var isEditingKey = false
    @State private var voices: [ElevenLabsVoice] = []
    @State private var selectedVoiceID: String?
    @State private var isLoadingVoices = false
    @State private var voiceError: String?
    @State private var isTesting = false
    @State private var testDiagnostic = ""
    @State private var testSynthesizer: AVSpeechSynthesizer?
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    @State private var selectedSystemVoiceID: String?

    private var isElevenLabsSelected: Bool {
        ttsEngine == TTSEngineType.elevenLabs.rawValue
    }

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.lg) {
                    testVoiceSection
                    ttsEngineSection

                    if isElevenLabsSelected {
                        elevenLabsSection
                    } else {
                        systemVoiceSection
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

        // Bare-bones test: raw AVSpeechSynthesizer, NO custom audio session.
        // Stored in @State to guarantee retention during speech.
        let synth = AVSpeechSynthesizer()
        testSynthesizer = synth

        let utterance = AVSpeechUtterance(string: "Test. One. Two. Three.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 1.0

        let voiceName = utterance.voice?.name ?? "nil"
        let voiceLang = utterance.voice?.language ?? "nil"
        testDiagnostic = "Voice: \(voiceName) (\(voiceLang))"

        synth.speak(utterance)

        // Poll for completion since we're not using delegate
        Task {
            try? await Task.sleep(for: .seconds(1))
            let started = synth.isSpeaking
            testDiagnostic = started
                ? "Synth IS speaking — audio routing issue"
                : "Synth NOT speaking — synthesizer issue"

            // Wait for it to finish
            while synth.isSpeaking {
                try? await Task.sleep(for: .milliseconds(200))
            }
            try? await Task.sleep(for: .seconds(1))
            testSynthesizer = nil
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
        }

        // Load ElevenLabs state
        do {
            let key = try await appServices.keychainManager.getElevenLabsKey()
            hasElevenLabsKey = key != nil && !(key?.isEmpty ?? true)
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

    private func saveSystemVoice(_ identifier: String?) {
        guard let persona = fetchActivePersona() else { return }
        persona.systemTTSVoice = identifier
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
        case .elevenLabs: "waveform.circle.fill"
        }
    }

    private var engineSubtitle: String {
        switch engine {
        case .system: "Built-in iOS voice synthesis — free, no setup"
        case .elevenLabs: "Ultra-realistic AI voices — requires API key"
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
