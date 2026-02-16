import SwiftUI

struct TryItFreeStepView: View {
    let viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var pulseMic = false
    @State private var hasTriedVoice = false

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: CarChatTheme.Spacing.xxl) {
                Spacer()

                // Hero text
                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Text("Try It Free")
                        .font(CarChatTheme.Typography.heroTitle)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Text("Tap the mic and say something — it's free")
                        .font(CarChatTheme.Typography.body)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CarChatTheme.Spacing.xxl)
                }
                .opacity(showContent ? 1 : 0)

                // Large mic button
                ZStack {
                    // Pulsing glow ring
                    Circle()
                        .fill(CarChatTheme.Colors.glowCyan)
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .opacity(pulseMic ? 0.6 : 0.2)

                    Button {
                        Haptics.tap()
                        hasTriedVoice = true
                        viewModel.tryFreeVoice()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(CarChatTheme.Gradients.accent)
                                .frame(width: 100, height: 100)

                            Image(systemName: "mic.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                    .accessibilityLabel("Start free voice conversation")
                    .scaleEffect(pulseMic ? 1.05 : 1.0)
                }
                .opacity(showContent ? 1 : 0)

                // Post-try CTA
                if hasTriedVoice {
                    VStack(spacing: CarChatTheme.Spacing.md) {
                        Text("Want better voice quality?")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        HStack(spacing: CarChatTheme.Spacing.md) {
                            Button("Hear the Difference") {
                                Haptics.tap()
                                viewModel.advance()
                            }
                            .buttonStyle(.carChatPrimary)

                            Button("Start Free") {
                                Haptics.tap()
                                viewModel.skipToReady()
                            }
                            .buttonStyle(.carChatSecondary)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Skip button
                if !hasTriedVoice {
                    Button("Skip") {
                        viewModel.advance()
                    }
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    .padding(.bottom, CarChatTheme.Spacing.xxl)
                }
            }
            .padding(.horizontal, CarChatTheme.Spacing.xl)
        }
        .onAppear {
            withAnimation(CarChatTheme.Animation.smooth.delay(0.2)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseMic = true
            }
        }
    }
}
