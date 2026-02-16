import SwiftUI

struct SettingsView: View {
    @Environment(AppServices.self) private var appServices
    @State private var versionTapCount = 0
    @State private var showPaywall = false
    @State private var showBYOKConfirm = false

    private var isBYOK: Bool { appServices.authManager.authState.isBYOK }
    private var tier: SubscriptionTier { appServices.effectiveTier }

    var body: some View {
        NavigationStack {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CarChatTheme.Spacing.md) {
                        // Subscription section
                        SettingsSection(title: "Subscription", subtitle: "Manage your plan and usage") {
                            // Current plan row
                            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                HStack(spacing: CarChatTheme.Spacing.sm) {
                                    LayeredFeatureIcon(
                                        systemName: "crown",
                                        color: tierColor,
                                        accentShape: .none
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tier.displayName)
                                            .font(CarChatTheme.Typography.headline)
                                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                        if tier != .byok {
                                            Text("\(appServices.usageTracker.remainingMinutes) min remaining")
                                                .font(CarChatTheme.Typography.caption)
                                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                        } else {
                                            Text("Using your own API keys")
                                                .font(CarChatTheme.Typography.caption)
                                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                        }
                                    }

                                    Spacer()

                                    if tier == .free || tier == .standard {
                                        Button("Upgrade") {
                                            Haptics.tap()
                                            showPaywall = true
                                        }
                                        .font(CarChatTheme.Typography.callout)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, CarChatTheme.Spacing.sm)
                                        .padding(.vertical, CarChatTheme.Spacing.xs)
                                        .background(CarChatTheme.Gradients.accent)
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            SettingsRow(
                                icon: "chart.bar",
                                title: "Usage",
                                color: CarChatTheme.Colors.listening,
                                destination: UsageDashboardView()
                            )
                        }

                        SettingsSection(title: "AI Providers", subtitle: Microcopy.Settings.aiProviders) {
                            SettingsRow(
                                icon: "cpu",
                                title: "AI Providers",
                                color: CarChatTheme.Colors.accentGradientStart,
                                destination: APIKeySettingsView()
                            )
                        }

                        SettingsSection(title: "Voice", subtitle: Microcopy.Settings.voice) {
                            SettingsRow(
                                icon: "waveform",
                                title: "Voice Settings",
                                color: CarChatTheme.Colors.speaking,
                                destination: VoiceSettingsView()
                            )
                        }

                        SettingsSection(title: "Personas", subtitle: Microcopy.Settings.personas) {
                            SettingsRow(
                                icon: "person.crop.circle",
                                title: "Manage Personas",
                                color: CarChatTheme.Colors.processing,
                                destination: PersonaSettingsView()
                            )
                        }

                        // Advanced section (BYOK toggle)
                        SettingsSection(title: "Advanced") {
                            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                HStack(spacing: CarChatTheme.Spacing.sm) {
                                    LayeredFeatureIcon(
                                        systemName: "key",
                                        color: CarChatTheme.Colors.processing,
                                        accentShape: .none
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Power User Mode")
                                            .font(CarChatTheme.Typography.headline)
                                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                        Text("Use your own API keys")
                                            .font(CarChatTheme.Typography.caption)
                                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { isBYOK },
                                        set: { newValue in
                                            if newValue {
                                                showBYOKConfirm = true
                                            } else {
                                                appServices.authManager.disableBYOKMode()
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(CarChatTheme.Colors.accentGradientStart)
                                }
                            }

                            if isBYOK {
                                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                    HStack(spacing: CarChatTheme.Spacing.xs) {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(CarChatTheme.Colors.processing)

                                        Text("Power User Mode — No usage limits, direct API connections")
                                            .font(CarChatTheme.Typography.caption)
                                            .foregroundStyle(CarChatTheme.Colors.textSecondary)
                                    }
                                }
                            }
                        }

                        SettingsSection(title: "About", subtitle: Microcopy.Settings.about) {
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

                                    Text(versionLabel)
                                        .font(CarChatTheme.Typography.caption)
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                        .contentTransition(.numericText())
                                }
                            }
                            .onTapGesture {
                                versionTapCount += 1
                                Haptics.tap()
                            }
                            .accessibilityLabel("Version \(versionLabel)")
                            .accessibilityAddTraits(.isStaticText)
                        }

                        // Footer
                        Text("Made with love for the open road")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary.opacity(0.5))
                            .padding(.top, CarChatTheme.Spacing.lg)
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.md)
                    .padding(.top, CarChatTheme.Spacing.sm)
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Enable Power User Mode?", isPresented: $showBYOKConfirm) {
            Button("Enable") {
                appServices.authManager.enableBYOKMode()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This disables managed billing and uses your own API keys directly. You'll need to configure keys in AI Providers.")
        }
    }

    private var tierColor: Color {
        switch tier {
        case .free: CarChatTheme.Colors.textTertiary
        case .standard: CarChatTheme.Colors.accentGradientStart
        case .premium: CarChatTheme.Colors.speaking
        case .byok: CarChatTheme.Colors.processing
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        if versionTapCount >= 7 {
            return "\(version) (you found me!)"
        }
        return version
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    .accessibilityAddTraits(.isHeader)

                if let subtitle {
                    Text(subtitle)
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary.opacity(0.6))
                }
            }
            .padding(.horizontal, CarChatTheme.Spacing.xs)

            content()
        }
        .scrollTransition(.animated.threshold(.visible(0.9))) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.5)
                .scaleEffect(phase.isIdentity ? 1 : 0.96)
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
        .sensoryFeedback(.selection, trigger: false)
        .accessibilityLabel(title)
        .accessibilityHint("Opens \(title.lowercased())")
    }
}
