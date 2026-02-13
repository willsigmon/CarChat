import SwiftUI

struct APIKeyStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showContent = false

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: CarChatTheme.Spacing.xxl) {
                Spacer()

                // Hero icon
                GradientIcon(
                    systemName: "key.fill",
                    gradient: CarChatTheme.Gradients.accent,
                    size: 72,
                    iconSize: 30,
                    glowColor: CarChatTheme.Colors.glowCyan
                )
                .opacity(showContent ? 1 : 0)

                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Text("Connect an AI Provider")
                        .font(CarChatTheme.Typography.title)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Text("Enter an API key to get started.\nYou can add more providers later.")
                        .font(CarChatTheme.Typography.body)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                }
                .opacity(showContent ? 1 : 0)

                // Provider picker + key field
                VStack(spacing: CarChatTheme.Spacing.md) {
                    // Provider picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: CarChatTheme.Spacing.xs) {
                            ForEach(
                                AIProviderType.allCases.filter(\.requiresAPIKey)
                            ) { provider in
                                ProviderChip(
                                    provider: provider,
                                    isSelected: viewModel.selectedProvider == provider
                                ) {
                                    viewModel.selectedProvider = provider
                                }
                            }
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                    }

                    // API key field
                    GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)

                            SecureField("API Key", text: $viewModel.apiKey)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                }
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Action buttons
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Button("Continue") {
                        viewModel.advance()
                    }
                    .buttonStyle(.carChatPrimary)
                    .disabled(viewModel.apiKey.isEmpty)

                    Button("Skip for Now") {
                        viewModel.advance()
                    }
                    .buttonStyle(.carChatGhost)
                }
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Provider Chip

private struct ProviderChip: View {
    let provider: AIProviderType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CarChatTheme.Spacing.xs) {
                ProviderIcon(provider: provider, size: 24)

                Text(provider.displayName)
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(
                        isSelected
                            ? CarChatTheme.Colors.textPrimary
                            : CarChatTheme.Colors.textTertiary
                    )
            }
            .padding(.horizontal, CarChatTheme.Spacing.sm)
            .padding(.vertical, CarChatTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? CarChatTheme.Colors.providerColor(provider).opacity(0.15)
                            : CarChatTheme.Colors.surfaceSecondary
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected
                            ? CarChatTheme.Colors.providerColor(provider).opacity(0.3)
                            : Color.white.opacity(0.06),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(CarChatTheme.Animation.fast, value: isSelected)
    }
}
