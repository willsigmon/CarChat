import SwiftUI

struct ConversationView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: ConversationViewModel?

    var body: some View {
        Group {
            if let viewModel {
                voiceContent(viewModel)
            } else {
                ZStack {
                    CarChatTheme.Colors.background.ignoresSafeArea()
                    ProgressView()
                        .tint(CarChatTheme.Colors.accentGradientStart)
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ConversationViewModel(appServices: appServices)
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
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private func statusIndicator(_ vm: ConversationViewModel) -> some View {
        HStack(spacing: CarChatTheme.Spacing.xs) {
            VoiceStateIcon(state: vm.voiceState)

            Group {
                switch vm.voiceState {
                case .idle:
                    Text("Tap to talk")
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                case .listening:
                    Text("Listening...")
                        .foregroundStyle(CarChatTheme.Colors.listening)
                case .processing:
                    Text("Thinking...")
                        .foregroundStyle(CarChatTheme.Colors.processing)
                case .speaking:
                    Text("Speaking...")
                        .foregroundStyle(CarChatTheme.Colors.speaking)
                case .error:
                    Text("Error")
                        .foregroundStyle(CarChatTheme.Colors.error)
                }
            }
            .font(CarChatTheme.Typography.statusLabel)
            .contentTransition(.numericText())
        }
        .padding(.horizontal, CarChatTheme.Spacing.md)
        .padding(.vertical, CarChatTheme.Spacing.xs)
        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
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

    @ViewBuilder
    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: CarChatTheme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(CarChatTheme.Colors.error)

            Text(error)
                .font(CarChatTheme.Typography.caption)
                .foregroundStyle(CarChatTheme.Colors.error.opacity(0.9))
                .lineLimit(2)
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
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(state.isActive ? 1.0 : 0.5)

            Text(state.isActive ? "Live" : "Ready")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(color)
        }
        .padding(.horizontal, CarChatTheme.Spacing.xs)
        .padding(.vertical, CarChatTheme.Spacing.xxs)
        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
    }
}
