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
            ZStack(alignment: .top) {
                // Step content
                Group {
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
                }

                // Step indicator + back button
                HStack {
                    // Back button (hidden on welcome)
                    if viewModel.currentStep != .welcome {
                        Button {
                            Haptics.tap()
                            viewModel.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                                .frame(width: 36, height: 36)
                                .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
                        }
                        .accessibilityLabel("Go back")
                        .transition(.opacity)
                    } else {
                        Color.clear.frame(width: 36, height: 36)
                    }

                    Spacer()

                    // Step dots
                    StepIndicator(
                        steps: OnboardingStep.allCases.count,
                        current: OnboardingStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0
                    )

                    Spacer()

                    // Spacer to balance
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .padding(.top, CarChatTheme.Spacing.sm)
                .animation(CarChatTheme.Animation.fast, value: viewModel.currentStep)
            }
            .animation(CarChatTheme.Animation.standard, value: viewModel.currentStep)
        } else {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()
                ProgressView()
                    .tint(CarChatTheme.Colors.accentGradientStart)
            }
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let steps: Int
    let current: Int

    var body: some View {
        HStack(spacing: CarChatTheme.Spacing.xs) {
            ForEach(0..<steps, id: \.self) { index in
                Circle()
                    .fill(
                        index == current
                            ? CarChatTheme.Colors.accentGradientStart
                            : CarChatTheme.Colors.textTertiary.opacity(0.4)
                    )
                    .frame(width: index == current ? 8 : 6, height: index == current ? 8 : 6)
                    .animation(CarChatTheme.Animation.springy, value: current)
            }
        }
        .accessibilityLabel("Step \(current + 1) of \(steps)")
    }
}

// MARK: - Ready Step

private enum ReadyPhase: CaseIterable {
    case start, scaleUp, wiggle, settle

    var scaleValue: CGFloat {
        switch self {
        case .start: 0.3
        case .scaleUp: 1.08
        case .wiggle: 1.0
        case .settle: 1.0
        }
    }

    var rotationValue: Double {
        switch self {
        case .start: 0
        case .scaleUp: 0
        case .wiggle: -3
        case .settle: 0
        }
    }

    var animation: Animation {
        switch self {
        case .start: .spring(response: 0.5, dampingFraction: 0.6)
        case .scaleUp: .spring(response: 0.3, dampingFraction: 0.5)
        case .wiggle: .easeInOut(duration: 0.15)
        case .settle: .spring(response: 0.4, dampingFraction: 0.8)
        }
    }
}

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

                // Animated success icon with phase animator
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
                    .phaseAnimator(
                        ReadyPhase.allCases,
                        trigger: showCheck
                    ) { content, phase in
                        content
                            .scaleEffect(phase.scaleValue)
                            .rotationEffect(.degrees(phase.rotationValue))
                            .opacity(phase == .start ? 0 : 1)
                    } animation: { phase in
                        phase.animation
                    }
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
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showCheck = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }
        }
    }
}
