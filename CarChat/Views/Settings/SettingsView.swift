import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CarChatTheme.Spacing.md) {
                        SettingsSection(title: "AI Providers") {
                            SettingsRow(
                                icon: "key.fill",
                                title: "API Keys",
                                color: CarChatTheme.Colors.accentGradientStart,
                                destination: APIKeySettingsView()
                            )
                        }

                        SettingsSection(title: "Voice") {
                            SettingsRow(
                                icon: "waveform",
                                title: "Voice Settings",
                                color: CarChatTheme.Colors.speaking,
                                destination: VoiceSettingsView()
                            )
                        }

                        SettingsSection(title: "Personas") {
                            SettingsRow(
                                icon: "person.crop.circle",
                                title: "Manage Personas",
                                color: CarChatTheme.Colors.processing,
                                destination: PersonaSettingsView()
                            )
                        }

                        SettingsSection(title: "About") {
                            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                HStack {
                                    HStack(spacing: CarChatTheme.Spacing.sm) {
                                        LayeredFeatureIcon(
                                            systemName: "info.circle",
                                            color: CarChatTheme.Colors.textSecondary,
                                            accentShape: .none
                                        )

                                        Text("Version")
                                            .font(CarChatTheme.Typography.headline)
                                            .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                    }

                                    Spacer()

                                    Text(
                                        Bundle.main.infoDictionary?[
                                            "CFBundleShortVersionString"
                                        ] as? String ?? "1.0"
                                    )
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.md)
                    .padding(.top, CarChatTheme.Spacing.sm)
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            content()
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: icon,
                        color: color,
                        accentShape: .none
                    )

                    Text(title)
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }
            }
        }
    }
}
