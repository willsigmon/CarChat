import SwiftUI

struct ConversationView: View {
    @Environment(AppServices.self) private var appServices
    @AppStorage("audioOutputMode") private var audioOutputMode = AudioOutputMode.defaultMode.rawValue
    @State private var viewModel: ConversationViewModel?
    @State private var showSuggestions = false
    @State private var suggestions: [PromptSuggestions.Suggestion] = []
    @State private var statusLabel = Microcopy.Status.label(for: .idle)
    @State private var showSettings = false

    var body: some View {
        Group {
            if let viewModel {
                voiceContent(viewModel)
            } else {
                loadingState
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ConversationViewModel(appServices: appServices)
            }
        }
    }

    // MARK: - Loading State

    @ViewBuilder
    private var loadingState: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: CarChatTheme.Spacing.md) {
                Image(systemName: "car.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(CarChatTheme.Gradients.accent)
                    .symbolEffect(.pulse.byLayer, options: .repeating)

                Text(Microcopy.Loading.message)
                    .font(CarChatTheme.Typography.callout)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
        }
    }

    @ViewBuilder
    private func voiceContent(_ vm: ConversationViewModel) -> some View {
        ZStack {
            // Immersive animated background
            AmbientBackground(state: vm.voiceState)

            // Floating particles
            FloatingParticles(
                count: 20,
                isActive: vm.voiceState.isActive,
                color: particleColor(for: vm.voiceState)
            )

            // Main content
            VStack(spacing: 0) {
                // Top bar with persona & provider
                topBar(vm)
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                    .padding(.top, CarChatTheme.Spacing.sm)

                if !vm.voiceState.isActive && showSuggestions {
                    // Idle: keep suggestions discoverable and scrollable
                    Spacer(minLength: CarChatTheme.Spacing.md)

                    ScrollView(.vertical, showsIndicators: false) {
                        SuggestionChipsView(
                            suggestions: suggestions,
                            onTap: { suggestion in
                                withAnimation(CarChatTheme.Animation.fast) {
                                    showSuggestions = false
                                }
                                vm.sendPrompt(suggestion.text)
                            },
                            onRefresh: {
                                refreshSuggestions()
                            }
                        )
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .padding(.vertical, CarChatTheme.Spacing.xs)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    .frame(maxHeight: 520)
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [
                                .clear,
                                CarChatTheme.Colors.background.opacity(0.24),
                                CarChatTheme.Colors.background.opacity(0.48)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 34)
                        .allowsHitTesting(false)
                    }

                    Spacer(minLength: CarChatTheme.Spacing.md)
                } else {
                    Spacer()

                    // Status indicator
                    statusIndicator(vm)
                        .padding(.bottom, CarChatTheme.Spacing.md)

                    if vm.voiceState == .speaking {
                        speakingCaptionArea(vm)
                            .padding(.horizontal, CarChatTheme.Spacing.xl)
                            .padding(.top, CarChatTheme.Spacing.xs)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        // Waveform visualization
                        VoiceWaveformView(level: vm.audioLevel, state: vm.voiceState)
                            .frame(height: 160)

                        // Transcript area
                        transcriptArea(vm)
                            .padding(.horizontal, CarChatTheme.Spacing.xxl)
                            .frame(minHeight: 80)
                            .padding(.top, CarChatTheme.Spacing.md)
                    }
                }

                // Error banner
                if let error = vm.errorMessage {
                    errorBanner(error)
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                        .padding(.top, CarChatTheme.Spacing.xs)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Premium mic button
                MicButton(state: vm.voiceState) {
                    vm.toggleListening()
                }
                .padding(.bottom, CarChatTheme.Spacing.huge)
                .zIndex(5)
            }
        }
        .animation(CarChatTheme.Animation.fast, value: vm.voiceState)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                APIKeySettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: vm.voiceState) { oldState, newState in
            // Haptic per state transition with sound companions
            Haptics.voiceStateChanged(to: newState)
            switch newState {
            case .listening where oldState == .idle:
                Haptics.listeningStartSound()
            case .speaking where oldState != .speaking:
                Haptics.speakingStartSound()
            case .error:
                Haptics.errorSound()
            default:
                break
            }

            // Refresh status label on each transition
            withAnimation(CarChatTheme.Animation.fast) {
                statusLabel = Microcopy.Status.label(for: newState)
            }

            // Refresh suggestions when returning to idle
            if newState == .idle && oldState != .idle {
                refreshSuggestions()
                withAnimation(CarChatTheme.Animation.smooth) {
                    showSuggestions = true
                }
            }
        }
        .onAppear {
            refreshSuggestions()
            // Delayed entrance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(CarChatTheme.Animation.smooth) {
                    showSuggestions = true
                }
            }
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func topBar(_ vm: ConversationViewModel) -> some View {
        HStack {
            // App branding
            HStack(spacing: CarChatTheme.Spacing.xs) {
                Image(systemName: "car.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CarChatTheme.Colors.accentGradientStart)

                Text("CarChat")
                    .font(CarChatTheme.Typography.callout)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
            }

            Spacer()

            Menu {
                ForEach(AudioOutputMode.allCases) { mode in
                    Button {
                        audioOutputMode = mode.rawValue
                        AudioSessionManager.shared.setPreferredOutputMode(mode)
                        Haptics.tap()
                    } label: {
                        Label(
                            mode.displayName,
                            systemImage: mode == currentOutputMode ? "checkmark" : "speaker.wave.2"
                        )
                    }
                }
            } label: {
                HStack(spacing: CarChatTheme.Spacing.xxxs) {
                    Image(systemName: outputModeIconName)
                    Text(outputModeDisplayName)
                        .font(CarChatTheme.Typography.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(outputModeColor)
                .padding(.horizontal, CarChatTheme.Spacing.xs)
                .padding(.vertical, 7)
                .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
            }
            .accessibilityLabel("Audio output: \(outputModeDisplayName)")
            .accessibilityHint("Opens audio output options including speakerphone mode")

            // Voice state badge
            VoiceStateBadge(state: vm.voiceState)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("CarChat, \(vm.voiceState.isActive ? "Live" : "Ready")")
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private func statusIndicator(_ vm: ConversationViewModel) -> some View {
        HStack(spacing: CarChatTheme.Spacing.xs) {
            VoiceStateIcon(state: vm.voiceState)

            Text(statusLabel)
                .font(CarChatTheme.Typography.statusLabel)
                .foregroundStyle(stateColor(for: vm.voiceState))
                .contentTransition(.numericText())
                .id(statusLabel)
        }
        .padding(.horizontal, CarChatTheme.Spacing.md)
        .padding(.vertical, CarChatTheme.Spacing.xs)
        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(statusLabel)")
    }

    // MARK: - Transcript Area

    @ViewBuilder
    private func transcriptArea(_ vm: ConversationViewModel) -> some View {
        VStack(spacing: CarChatTheme.Spacing.sm) {
            if !vm.currentTranscript.isEmpty {
                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Circle()
                            .fill(CarChatTheme.Colors.listening)
                            .frame(width: 6, height: 6)

                        Text(vm.currentTranscript)
                            .font(CarChatTheme.Typography.transcriptUser)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)
                            .lineLimit(4)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            if !vm.assistantTranscript.isEmpty {
                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Circle()
                            .fill(CarChatTheme.Colors.speaking)
                            .frame(width: 6, height: 6)

                        Text(vm.assistantTranscript)
                            .font(CarChatTheme.Typography.transcriptAssistant)
                            .foregroundStyle(CarChatTheme.Colors.textSecondary)
                            .lineLimit(6)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .multilineTextAlignment(.leading)
    }

    // MARK: - Speaking Caption Area

    @ViewBuilder
    private func speakingCaptionArea(_ vm: ConversationViewModel) -> some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.xs) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CarChatTheme.Colors.speaking)
                        .symbolEffect(.variableColor.iterative, options: .repeating)

                    Text("NOW TALKING")
                        .font(CarChatTheme.Typography.micro.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(CarChatTheme.Colors.speaking)

                    Spacer()

                    SpeakingCueView()
                }

                Text(
                    vm.assistantTranscript.isEmpty
                        ? "Generating spoken response…"
                        : vm.assistantTranscript
                )
                .font(CarChatTheme.Typography.body.weight(.semibold))
                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                .lineSpacing(3)
                .lineLimit(8)
                .multilineTextAlignment(.leading)

                Text("Captions stay in sync while speech is playing")
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.md, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            CarChatTheme.Colors.speaking.opacity(0.45),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Now talking. \(vm.assistantTranscript)")
    }

    // MARK: - Error Banner

    private var isAPIKeyError: Bool {
        guard let error = viewModel?.errorMessage?.lowercased() else { return false }
        return error.contains("api") || error.contains("key") || error.contains("auth")
            || error.contains("401") || error.contains("403")
    }

    @ViewBuilder
    private func errorBanner(_ error: String) -> some View {
        VStack(spacing: CarChatTheme.Spacing.xs) {
            HStack(spacing: CarChatTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(CarChatTheme.Colors.error)

                Text(error)
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.error.opacity(0.9))
                    .lineLimit(2)

                Spacer()
            }

            HStack(spacing: CarChatTheme.Spacing.xs) {
                Button {
                    viewModel?.startListening()
                } label: {
                    HStack(spacing: CarChatTheme.Spacing.xxs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Try Again")
                            .font(CarChatTheme.Typography.caption)
                    }
                }
                .buttonStyle(.carChatActionPill(tone: .danger))
                .accessibilityLabel("Try again")
                .accessibilityHint("Retries the voice conversation")

                if isAPIKeyError {
                    Button {
                        showSettings = true
                    } label: {
                        HStack(spacing: CarChatTheme.Spacing.xxs) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Settings")
                                .font(CarChatTheme.Typography.caption)
                        }
                    }
                    .buttonStyle(.carChatActionPill(tone: .accent))
                    .accessibilityLabel("Open settings")
                    .accessibilityHint("Configure your API key")
                }

                Spacer()
            }
        }
        .padding(CarChatTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm)
                .fill(CarChatTheme.Colors.error.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm)
                        .strokeBorder(CarChatTheme.Colors.error.opacity(0.2), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error: \(error)")
    }

    // MARK: - Helpers

    private func particleColor(for state: VoiceSessionState) -> Color {
        switch state {
        case .idle: CarChatTheme.Colors.accentGradientStart
        case .listening: CarChatTheme.Colors.listening
        case .processing: CarChatTheme.Colors.processing
        case .speaking: CarChatTheme.Colors.speaking
        case .error: CarChatTheme.Colors.error
        }
    }

    private func stateColor(for state: VoiceSessionState) -> Color {
        switch state {
        case .idle: CarChatTheme.Colors.textTertiary
        case .listening: CarChatTheme.Colors.listening
        case .processing: CarChatTheme.Colors.processing
        case .speaking: CarChatTheme.Colors.speaking
        case .error: CarChatTheme.Colors.error
        }
    }

    private var outputModeDisplayName: String {
        currentOutputMode.displayName
    }

    private var outputModeIconName: String {
        switch currentOutputMode {
        case .automatic:
            return "point.3.connected.trianglepath.dotted"
        case .speakerphone:
            return "speaker.wave.3.fill"
        }
    }

    private var outputModeColor: Color {
        switch currentOutputMode {
        case .automatic:
            return CarChatTheme.Colors.textTertiary
        case .speakerphone:
            return CarChatTheme.Colors.accentGradientStart
        }
    }

    private var currentOutputMode: AudioOutputMode {
        AudioOutputMode(rawValue: audioOutputMode) ?? .defaultMode
    }

    private func refreshSuggestions() {
        suggestions = PromptSuggestions.current(count: 8)
    }
}

// MARK: - Voice State Badge

private struct VoiceStateBadge: View {
    let state: VoiceSessionState

    private var color: Color {
        switch state {
        case .idle: CarChatTheme.Colors.textTertiary
        case .listening: CarChatTheme.Colors.listening
        case .processing: CarChatTheme.Colors.processing
        case .speaking: CarChatTheme.Colors.speaking
        case .error: CarChatTheme.Colors.error
        }
    }

    var body: some View {
        StatusBadge(
            text: state.isActive ? "Live" : "Ready",
            color: color,
            isActive: state.isActive
        )
        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
    }
}

private struct SpeakingCueView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(CarChatTheme.Colors.speaking.opacity(0.9))
                    .frame(width: 4, height: 8 + CGFloat(index * 4))
                    .scaleEffect(y: animate ? 1.0 : 0.55, anchor: .bottom)
                    .animation(
                        .easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
