import SwiftUI

struct APIKeySettingsView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: SettingsViewModel?
    @State private var appeared = false

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.xl) {
                    // Cloud providers section
                    VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                        SectionHeader(
                            icon: "cloud.fill",
                            title: "Cloud",
                            subtitle: "Powerful models, needs an API key"
                        )

                        ForEach(Array(AIProviderType.cloudProviders.enumerated()), id: \.element.id) { index, provider in
                            if let viewModel {
                                ProviderCard(
                                    provider: provider,
                                    viewModel: viewModel
                                )
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.08),
                                    value: appeared
                                )
                            }
                        }
                    }

                    // Self-hosted providers section
                    if !AIProviderType.selfHostedProviders.isEmpty {
                        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                            SectionHeader(
                                icon: "server.rack",
                                title: "Self-Hosted",
                                subtitle: "Your own servers, your own rules"
                            )

                            ForEach(Array(AIProviderType.selfHostedProviders.enumerated()), id: \.element.id) { index, provider in
                                SelfHostedProviderCard(provider: provider)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 12)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.8)
                                            .delay(Double(AIProviderType.cloudProviders.count + index) * 0.08),
                                        value: appeared
                                    )
                            }
                        }
                    }

                    // Local providers section
                    VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                        SectionHeader(
                            icon: "internaldrive.fill",
                            title: "On-Device",
                            subtitle: "Private, free, no internet needed"
                        )

                        ForEach(Array(AIProviderType.localProviders.enumerated()), id: \.element.id) { index, provider in
                            LocalProviderCard(provider: provider)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(AIProviderType.cloudProviders.count + index) * 0.08),
                                    value: appeared
                                )
                        }
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.top, CarChatTheme.Spacing.sm)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
            }
        }
        .navigationTitle("AI Providers")
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(appServices: appServices)
            }
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: CarChatTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)

            Text(title.uppercased())
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)

            Text("  \(subtitle)")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary.opacity(0.6))

            Spacer()
        }
        .padding(.horizontal, CarChatTheme.Spacing.xs)
    }
}

// MARK: - Provider Card (Cloud)

private struct ProviderCard: View {
    let provider: AIProviderType
    @Bindable var viewModel: SettingsViewModel
    @State private var isEditing = false
    @State private var editedKey = ""

    private var hasKey: Bool {
        let key = viewModel.apiKeys[provider] ?? ""
        return !key.isEmpty
    }

    private var brandColor: Color {
        CarChatTheme.Colors.providerColor(provider)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: CarChatTheme.Spacing.md) {
                // Brand logo
                BrandLogoCard(provider, size: 52)

                // Provider info
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxxs) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Text(provider.displayName)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        if hasKey {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(CarChatTheme.Colors.success)
                        }
                    }

                    Text(provider.tagline)
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }

                Spacer()

                // Action button
                if !isEditing {
                    Button {
                        editedKey = viewModel.apiKeys[provider] ?? ""
                        withAnimation(CarChatTheme.Animation.fast) {
                            isEditing = true
                        }
                    } label: {
                        Text(hasKey ? "Update" : "Add Key")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(hasKey ? CarChatTheme.Colors.textTertiary : brandColor)
                            .padding(.horizontal, CarChatTheme.Spacing.sm)
                            .padding(.vertical, CarChatTheme.Spacing.xxs)
                            .background(
                                Capsule().fill(
                                    hasKey
                                        ? CarChatTheme.Colors.surfaceGlass
                                        : brandColor.opacity(0.15)
                                )
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    hasKey
                                        ? Color.white.opacity(0.06)
                                        : brandColor.opacity(0.3),
                                    lineWidth: 0.5
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(CarChatTheme.Spacing.md)

            // Expanded key input
            if isEditing {
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Divider()
                        .background(brandColor.opacity(0.2))

                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(brandColor.opacity(0.6))

                        SecureField("Paste your API key", text: $editedKey)
                            .font(CarChatTheme.Typography.body)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .tint(brandColor)
                    }
                    .padding(CarChatTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm)
                            .fill(CarChatTheme.Colors.surfaceSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm)
                            .strokeBorder(brandColor.opacity(0.15), lineWidth: 0.5)
                    )

                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Button("Cancel") {
                            withAnimation(CarChatTheme.Animation.fast) {
                                isEditing = false
                            }
                        }
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .padding(.vertical, CarChatTheme.Spacing.xs)

                        Spacer()

                        Button {
                            viewModel.saveKey(for: provider, key: editedKey)
                            Haptics.tap()
                            withAnimation(CarChatTheme.Animation.fast) {
                                isEditing = false
                            }
                        } label: {
                            Text("Save")
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, CarChatTheme.Spacing.lg)
                                .padding(.vertical, CarChatTheme.Spacing.xs)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [brandColor, brandColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(editedKey.isEmpty)
                        .opacity(editedKey.isEmpty ? 0.5 : 1)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.bottom, CarChatTheme.Spacing.md)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .fill(.ultraThinMaterial.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            hasKey ? brandColor.opacity(0.25) : Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(provider.displayName), \(hasKey ? "configured" : "not configured")")
    }
}

// MARK: - Local Provider Card

private struct LocalProviderCard: View {
    let provider: AIProviderType

    private var brandColor: Color {
        CarChatTheme.Colors.providerColor(provider)
    }

    var body: some View {
        HStack(spacing: CarChatTheme.Spacing.md) {
            BrandLogoCard(provider, size: 52)

            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxxs) {
                Text(provider.displayName)
                    .font(CarChatTheme.Typography.headline)
                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                Text(provider.tagline)
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }

            Spacer()

            if provider.isAvailable {
                Text("Free")
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.success)
                    .padding(.horizontal, CarChatTheme.Spacing.sm)
                    .padding(.vertical, CarChatTheme.Spacing.xxs)
                    .background(
                        Capsule().fill(CarChatTheme.Colors.success.opacity(0.12))
                    )
                    .overlay(
                        Capsule().strokeBorder(CarChatTheme.Colors.success.opacity(0.2), lineWidth: 0.5)
                    )
            } else {
                Text("Coming Soon")
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    .padding(.horizontal, CarChatTheme.Spacing.sm)
                    .padding(.vertical, CarChatTheme.Spacing.xxs)
                    .background(
                        Capsule().fill(CarChatTheme.Colors.surfaceGlass)
                    )
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            }
        }
        .padding(CarChatTheme.Spacing.md)
        .opacity(provider.isAvailable ? 1.0 : 0.6)
        .background(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .fill(.ultraThinMaterial.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .accessibilityLabel("\(provider.displayName), \(provider.isAvailable ? "free, no API key needed" : "coming soon")")
    }
}

// MARK: - Self-Hosted Provider Card

private struct SelfHostedProviderCard: View {
    let provider: AIProviderType
    @State private var baseURL: String = ""
    @State private var isEditing = false
    @State private var isTesting = false
    @State private var testResult: Bool?

    private var brandColor: Color {
        CarChatTheme.Colors.providerColor(provider)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: CarChatTheme.Spacing.md) {
                BrandLogoCard(provider, size: 52)

                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxxs) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Text(provider.displayName)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text("Self-Hosted")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(brandColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(brandColor.opacity(0.12))
                            )
                    }

                    Text(provider.tagline)
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }

                Spacer()

                if !isEditing {
                    Button {
                        baseURL = UserDefaults.standard.string(forKey: "openclawBaseURL") ?? ""
                        withAnimation(CarChatTheme.Animation.fast) {
                            isEditing = true
                        }
                    } label: {
                        Text("Configure")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(brandColor)
                            .padding(.horizontal, CarChatTheme.Spacing.sm)
                            .padding(.vertical, CarChatTheme.Spacing.xxs)
                            .background(
                                Capsule().fill(brandColor.opacity(0.15))
                            )
                            .overlay(
                                Capsule().strokeBorder(brandColor.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(CarChatTheme.Spacing.md)

            if isEditing {
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Divider()
                        .background(brandColor.opacity(0.2))

                    VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                        Text("Base URL")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)

                        HStack(spacing: CarChatTheme.Spacing.xs) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundStyle(brandColor.opacity(0.6))

                            TextField("http://your-server:8101", text: $baseURL)
                                .font(CarChatTheme.Typography.body)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .tint(brandColor)
                        }
                        .padding(CarChatTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm)
                                .fill(CarChatTheme.Colors.surfaceSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm)
                                .strokeBorder(brandColor.opacity(0.15), lineWidth: 0.5)
                        )
                    }

                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Button("Cancel") {
                            withAnimation(CarChatTheme.Animation.fast) {
                                isEditing = false
                                testResult = nil
                            }
                        }
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .padding(.vertical, CarChatTheme.Spacing.xs)

                        Button {
                            testConnection()
                        } label: {
                            HStack(spacing: 4) {
                                if isTesting {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .tint(.white)
                                } else {
                                    Image(systemName: testResult == true ? "checkmark" : "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(testResult == true ? "Connected" : "Test")
                                    .font(CarChatTheme.Typography.caption)
                            }
                            .foregroundStyle(testResult == true ? CarChatTheme.Colors.success : CarChatTheme.Colors.textSecondary)
                            .padding(.horizontal, CarChatTheme.Spacing.sm)
                            .padding(.vertical, CarChatTheme.Spacing.xs)
                            .background(
                                Capsule().fill(CarChatTheme.Colors.surfaceGlass)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isTesting)

                        Spacer()

                        Button {
                            UserDefaults.standard.set(baseURL, forKey: "openclawBaseURL")
                            Haptics.tap()
                            withAnimation(CarChatTheme.Animation.fast) {
                                isEditing = false
                            }
                        } label: {
                            Text("Save")
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, CarChatTheme.Spacing.lg)
                                .padding(.vertical, CarChatTheme.Spacing.xs)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [brandColor, brandColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(baseURL.isEmpty)
                        .opacity(baseURL.isEmpty ? 0.5 : 1)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.bottom, CarChatTheme.Spacing.md)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .fill(.ultraThinMaterial.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            brandColor.opacity(0.25),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(provider.displayName), self-hosted")
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            do {
                let provider = try AIProviderFactory.create(
                    type: .openclaw,
                    apiKey: nil
                )
                let result = try await provider.validateKey()
                testResult = result
            } catch {
                testResult = false
            }
            isTesting = false
        }
    }
}
