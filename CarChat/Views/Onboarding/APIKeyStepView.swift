import SwiftUI

struct APIKeyStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showContent = false
    @State private var selectedCategory: ProviderCategory = .cloud

    enum ProviderCategory: String, CaseIterable {
        case cloud = "Cloud"
        case local = "On-Device"
    }

    private var visibleCloudProviders: [AIProviderType] {
        AIProviderType.cloudProviders.filter { provider in
            ProviderAccessPolicy.canShowInUI(
                provider: provider,
                tier: viewModel.effectiveTier,
                surface: .iPhone
            )
        }
    }

    private var visibleLocalProviders: [AIProviderType] {
        AIProviderType.localProviders.filter { provider in
            ProviderAccessPolicy.canShowInUI(
                provider: provider,
                tier: viewModel.effectiveTier,
                surface: .iPhone
            )
        }
    }

    private func providers(for category: ProviderCategory) -> [AIProviderType] {
        category == .cloud ? visibleCloudProviders : visibleLocalProviders
    }

    private func selectFirstAvailableProvider(for category: ProviderCategory) {
        if let provider = providers(for: category).first {
            viewModel.selectedProvider = provider
        }
    }

    private var appleVisibilityNote: String? {
        if ProviderAccessPolicy.canShowInUI(
            provider: .apple,
            tier: viewModel.effectiveTier,
            surface: .iPhone
        ) {
            return nil
        }

        if !AIProviderType.apple.isAvailable {
            return "Apple Intelligence is unavailable in this build."
        }

        if !AIProviderType.apple.isAllowedForTier(viewModel.effectiveTier) {
            return "Apple Intelligence unlocks on Premium and BYOK."
        }

        if !AIProviderType.apple.isRuntimeAvailable {
            return "Apple Intelligence appears on iOS 26 or later."
        }

        return "Apple Intelligence is currently unavailable."
    }

    private var categorySummary: String {
        switch selectedCategory {
        case .cloud:
            return "Cloud models need an API key."
        case .local:
            return "On-device models are private and key-free."
        }
    }

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: CarChatTheme.Spacing.huge)

                // Hero — animated brand logo of selected provider
                ZStack {
                    // Glow ring behind the logo
                    Circle()
                        .fill(CarChatTheme.Colors.providerColor(viewModel.selectedProvider))
                        .frame(width: 100, height: 100)
                        .blur(radius: 30)
                        .opacity(showContent ? 0.4 : 0)

                    BrandLogoCard(viewModel.selectedProvider, size: 72)
                        .scaleEffect(showContent ? 1 : 0.7)
                }
                .animation(CarChatTheme.Animation.springy, value: viewModel.selectedProvider)
                .padding(.bottom, CarChatTheme.Spacing.lg)

                // Title + subtitle
                VStack(spacing: CarChatTheme.Spacing.xs) {
                    Text("Pick Your Brain")
                        .font(CarChatTheme.Typography.title)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Text("Pick where your AI runs.")
                        .font(CarChatTheme.Typography.body)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                }
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, CarChatTheme.Spacing.lg)

                // Cloud / On-Device toggle
                HStack(spacing: 0) {
                    ForEach(ProviderCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(CarChatTheme.Animation.fast) {
                                selectedCategory = category
                                // Auto-select first provider in this category.
                                selectFirstAvailableProvider(for: category)
                            }
                        } label: {
                            Text(category.rawValue)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(
                                    selectedCategory == category
                                        ? CarChatTheme.Colors.textPrimary
                                        : CarChatTheme.Colors.textTertiary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, CarChatTheme.Spacing.xs)
                                .background(
                                    selectedCategory == category
                                        ? Capsule().fill(CarChatTheme.Colors.surfaceGlass)
                                        : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    Capsule().fill(CarChatTheme.Colors.surfaceSecondary)
                )
                .padding(.horizontal, CarChatTheme.Spacing.xxxl)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, CarChatTheme.Spacing.xs)

                Text(categorySummary)
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, CarChatTheme.Spacing.sm)

                // Provider grid
                let providers = providers(for: selectedCategory)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CarChatTheme.Spacing.sm) {
                        ForEach(providers) { provider in
                            OnboardingProviderChip(
                                provider: provider,
                                isSelected: viewModel.selectedProvider == provider
                            ) {
                                withAnimation(CarChatTheme.Animation.springy) {
                                    viewModel.selectedProvider = provider
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                }
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, CarChatTheme.Spacing.lg)

                if let appleVisibilityNote {
                    GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 14))
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)

                            Text(appleVisibilityNote)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                    .padding(.bottom, CarChatTheme.Spacing.sm)
                    .transition(.opacity)
                }

                // API key field (only for cloud providers)
                if selectedCategory == .cloud {
                    GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    CarChatTheme.Colors.providerColor(viewModel.selectedProvider).opacity(0.6)
                                )

                            SecureField("Paste your API key", text: $viewModel.apiKey)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .tint(CarChatTheme.Colors.providerColor(viewModel.selectedProvider))
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                } else {
                    // Local provider info
                    GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(CarChatTheme.Colors.success)

                            Text("No API key needed. Runs privately on your device.")
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }

                Spacer()

                // Action buttons
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Button("Continue") {
                        viewModel.advance()
                    }
                    .buttonStyle(.carChatPrimary)
                    .disabled(selectedCategory == .cloud && viewModel.apiKey.isEmpty)

                    Button("Skip for Now") {
                        viewModel.advance()
                    }
                    .buttonStyle(.carChatGhost)
                }
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
            }
        }
        .onAppear {
            selectFirstAvailableProvider(for: selectedCategory)
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Onboarding Provider Chip

private struct OnboardingProviderChip: View {
    let provider: AIProviderType
    let isSelected: Bool
    let action: () -> Void

    private var brandColor: Color {
        CarChatTheme.Colors.providerColor(provider)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: CarChatTheme.Spacing.xs) {
                // Brand logo in a circle
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? brandColor.opacity(0.2)
                                : CarChatTheme.Colors.surfaceSecondary
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected
                                        ? brandColor.opacity(0.5)
                                        : Color.white.opacity(0.06),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )

                    BrandLogo(provider, size: 36, tint: isSelected ? brandColor : CarChatTheme.Colors.textTertiary)
                }

                Text(provider.shortName)
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(
                        isSelected
                            ? CarChatTheme.Colors.textPrimary
                            : CarChatTheme.Colors.textTertiary
                    )
            }
            .padding(.vertical, CarChatTheme.Spacing.xxs)
            .contentShape(Rectangle())
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(CarChatTheme.Animation.fast, value: isSelected)
        .accessibilityLabel(provider.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
