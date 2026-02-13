import SwiftUI

struct OnboardingContainerView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        contentView
            .task {
                if viewModel == nil {
                    viewModel = OnboardingViewModel(appServices: appServices)
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if let viewModel {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeStepView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .permissions:
                PermissionsStepView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .apiKey:
                APIKeyStepView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .ready:
                ReadyStepView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        } else {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()
                ProgressView()
                    .tint(CarChatTheme.Colors.accentGradientStart)
            }
        }
    }
}

// MARK: - Ready Step

private struct ReadyStepView: View {
    let viewModel: OnboardingViewModel

    @State private var showContent = false
    @State private var showCheck = false

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            // Celebration particles
            FloatingParticles(
                count: 25,
                isActive: true,
                color: CarChatTheme.Colors.success
            )

            VStack(spacing: CarChatTheme.Spacing.xxl) {
                Spacer()

                // Animated success icon
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(CarChatTheme.Colors.glowGreen)
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .opacity(showCheck ? 0.6 : 0)

                    GradientIcon(
                        systemName: "checkmark.circle.fill",
                        gradient: CarChatTheme.Gradients.listening,
                        size: 88,
                        iconSize: 40,
                        glowColor: CarChatTheme.Colors.glowGreen,
                        isAnimated: true
                    )
                    .scaleEffect(showCheck ? 1.0 : 0.3)
                    .opacity(showCheck ? 1.0 : 0)
                }

                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Text("You're All Set!")
                        .font(CarChatTheme.Typography.heroTitle)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Text("Tap the mic to start your first conversation.")
                        .font(CarChatTheme.Typography.body)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CarChatTheme.Spacing.xxxl)
                }
                .opacity(showContent ? 1 : 0)

                Spacer()

                Button("Get Started") {
                    viewModel.completeOnboarding()
                }
                .buttonStyle(.carChatPrimary)
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
                .opacity(showContent ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showCheck = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }
        }
    }
}
