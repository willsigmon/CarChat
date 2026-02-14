import SwiftUI

struct ConversationView: View {
    @Environment(AppServices.self) private var appServices
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
                    // Idle: center suggestions vertically
                    Spacer()

                    SuggestionChipsView(suggestions: suggestions) { suggestion in
                        withAnimation(CarChatTheme.Animation.fast) {
                            showSuggestions = false
                        }
                        vm.sendPrompt(suggestion.text)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .padding(.horizontal, CarChatTheme.Spacing.md)

                    Spacer()
                } else {
                    Spacer()

                    // Status indicator
                    statusIndicator(vm)
                        .padding(.bottom, CarChatTheme.Spacing.md)

                    // Waveform visualization
                    VoiceWaveformView(level: vm.audioLevel, state: vm.voiceState)
                        .frame(height: 160)

                    // Transcript area
                    transcriptArea(vm)
                        .padding(.horizontal, CarChatTheme.Spacing.xxl)
                        .frame(minHeight: 80)
                        .padding(.top, CarChatTheme.Spacing.md)
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
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.voiceState)
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
                suggestions = PromptSuggestions.current()
                withAnimation(CarChatTheme.Animation.smooth) {
                    showSuggestions = true
                }
            }
        }
        .onAppear {
            suggestions = PromptSuggestions.current()
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
                    Text("Try Again")
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, CarChatTheme.Spacing.sm)
                        .padding(.vertical, CarChatTheme.Spacing.xxs)
                        .background(Capsule().fill(CarChatTheme.Colors.error.opacity(0.3)))
                }
                .accessibilityLabel("Try again")
                .accessibilityHint("Retries the voice conversation")

                if isAPIKeyError {
                    Button {
                        showSettings = true
                    } label: {
                        Text("Settings")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                            .padding(.horizontal, CarChatTheme.Spacing.sm)
                            .padding(.vertical, CarChatTheme.Spacing.xxs)
                            .background(Capsule().fill(CarChatTheme.Colors.surfaceGlass))
                    }
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
