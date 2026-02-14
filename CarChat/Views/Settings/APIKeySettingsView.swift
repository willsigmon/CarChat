import SwiftUI

struct APIKeySettingsView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    ForEach(AIProviderType.allCases) { provider in
                        if provider.requiresAPIKey, let viewModel {
                            APIKeyCard(
                                provider: provider,
                                viewModel: viewModel
                            )
                        } else if !provider.requiresAPIKey {
                            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                HStack(spacing: CarChatTheme.Spacing.sm) {
                                    ProviderIcon(provider: provider, size: 36)

                                    Text(provider.displayName)
                                        .font(CarChatTheme.Typography.headline)
                                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                    Spacer()

                                    Text("No key needed")
                                        .font(CarChatTheme.Typography.caption)
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.top, CarChatTheme.Spacing.sm)
            }
        }
        .navigationTitle("API Keys")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(appServices: appServices)
            }
        }
    }
}

// MARK: - API Key Card

private struct APIKeyCard: View {
    let provider: AIProviderType
    @Bindable var viewModel: SettingsViewModel
    @State private var isEditing = false
    @State private var editedKey = ""

    private var hasKey: Bool {
        let key = viewModel.apiKeys[provider] ?? ""
        return !key.isEmpty
    }

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                // Header
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    ProviderIcon(provider: provider, size: 36)

                    Text(provider.displayName)
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Spacer()

                    // Status badge
                    StatusBadge(
                        text: hasKey ? "Configured" : "Not Set",
                        color: hasKey ? CarChatTheme.Colors.success : CarChatTheme.Colors.textTertiary
                    )
                }

                // Edit section
                if isEditing {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        HStack(spacing: CarChatTheme.Spacing.xs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)

                            SecureField("API Key", text: $editedKey)
                                .font(CarChatTheme.Typography.body)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        }
                        .padding(CarChatTheme.Spacing.xs)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                        Button("Save") {
                            viewModel.saveKey(for: provider, key: editedKey)
                            isEditing = false
                        }
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, CarChatTheme.Spacing.sm)
                        .padding(.vertical, CarChatTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(CarChatTheme.Gradients.accent)
                        )
                    }
                } else {
                    Button(hasKey ? "Update Key" : "Add Key") {
                        editedKey = viewModel.apiKeys[provider] ?? ""
                        isEditing = true
                    }
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                }
            }
        }
    }
}
