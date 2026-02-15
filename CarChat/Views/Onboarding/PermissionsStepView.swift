import SwiftUI

struct PermissionsStepView: View {
    let viewModel: OnboardingViewModel

    @State private var showContent = false

    private var allGranted: Bool {
        viewModel.hasMicPermission && viewModel.hasSpeechPermission
    }

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: CarChatTheme.Spacing.xxl) {
                Spacer()

                // Hero icon
                GradientIcon(
                    systemName: allGranted ? "checkmark.shield.fill" : "shield.checkered",
                    gradient: allGranted ? CarChatTheme.Gradients.listening : CarChatTheme.Gradients.accent,
                    size: 72,
                    iconSize: 32,
                    glowColor: allGranted ? CarChatTheme.Colors.glowGreen : CarChatTheme.Colors.glowCyan,
                    isAnimated: allGranted
                )
                .opacity(showContent ? 1 : 0)

                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Text(allGranted ? "All Set!" : "Permissions")
                        .font(CarChatTheme.Typography.title)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                        .contentTransition(.numericText())

                    Text(
                        allGranted
                            ? "Microphone and speech recognition are ready."
                            : "CarChat needs microphone and speech recognition to have voice conversations."
                    )
                    .font(CarChatTheme.Typography.body)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CarChatTheme.Spacing.xl)
                }
                .opacity(showContent ? 1 : 0)

                // Permission cards
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    PermissionCard(
                        icon: "mic.fill",
                        title: "Microphone",
                        description: "Capture your voice",
                        isGranted: viewModel.hasMicPermission
                    )

                    PermissionCard(
                        icon: "waveform",
                        title: "Speech Recognition",
                        description: "Transcribe your speech",
                        isGranted: viewModel.hasSpeechPermission
                    )
                }
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Action buttons
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    if allGranted {
                        Button("Continue") {
                            viewModel.advance()
                        }
                        .buttonStyle(.carChatPrimary)
                    } else {
                        Button("Grant Permissions") {
                            viewModel.requestPermissions()
                        }
                        .buttonStyle(.carChatPrimary)

                        Button("Skip for Now") {
                            viewModel.advance()
                        }
                        .buttonStyle(.carChatGhost)
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
            }
        }
        .animation(.default, value: allGranted)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Permission Card

private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
            HStack(spacing: CarChatTheme.Spacing.md) {
                LayeredFeatureIcon(
                    systemName: icon,
                    color: isGranted ? CarChatTheme.Colors.success : CarChatTheme.Colors.accentGradientStart,
                    accentShape: isGranted ? .none : .ring
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                    Text(description)
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }

                Spacer()

                // Status icon
                Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isGranted
                            ? CarChatTheme.Colors.success
                            : CarChatTheme.Colors.textTertiary
                    )
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .animation(.default, value: isGranted)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(isGranted ? "granted" : "not granted")")
        .accessibilityHint(description)
    }
}
