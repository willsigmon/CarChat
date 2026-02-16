import SwiftUI

struct UpgradePromptView: View {
    @Environment(AppServices.self) private var appServices
    let onDismiss: () -> Void
    let onUpgrade: () -> Void

    @State private var showContent = false

    private var remaining: Int { appServices.usageTracker.remainingMinutes }
    private var tier: SubscriptionTier { appServices.effectiveTier }

    var body: some View {
        VStack(spacing: CarChatTheme.Spacing.lg) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(CarChatTheme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, CarChatTheme.Spacing.sm)

            VStack(spacing: CarChatTheme.Spacing.md) {
                // Warning icon
                ZStack {
                    Circle()
                        .fill(CarChatTheme.Colors.glowAmber)
                        .frame(width: 60, height: 60)
                        .blur(radius: 15)

                    Image(systemName: remaining <= 0 ? "exclamationmark.circle.fill" : "clock.badge.exclamationmark")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(remaining <= 0 ? CarChatTheme.Colors.error : CarChatTheme.Colors.processing)
                }

                VStack(spacing: CarChatTheme.Spacing.xs) {
                    Text(headlineText)
                        .font(CarChatTheme.Typography.title)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitleText)
                        .font(CarChatTheme.Typography.body)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(showContent ? 1 : 0)

            // Actions
            VStack(spacing: CarChatTheme.Spacing.sm) {
                Button("Upgrade Now") {
                    Haptics.tap()
                    onUpgrade()
                }
                .buttonStyle(.carChatPrimary)

                Button("Not Now") {
                    onDismiss()
                }
                .font(CarChatTheme.Typography.headline)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
            .padding(.horizontal, CarChatTheme.Spacing.xl)
            .padding(.bottom, CarChatTheme.Spacing.xxl)
            .opacity(showContent ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.xl)
                .fill(CarChatTheme.Colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: CarChatTheme.Radius.xl)
                        .strokeBorder(CarChatTheme.Colors.borderMedium, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
        .onAppear {
            withAnimation(CarChatTheme.Animation.smooth.delay(0.1)) {
                showContent = true
            }
        }
    }

    private var headlineText: String {
        if remaining <= 0 {
            return "Minutes Exhausted"
        } else if remaining <= 2 {
            return "Running Low"
        } else {
            return "\(remaining) Minutes Left"
        }
    }

    private var subtitleText: String {
        let nextTier: SubscriptionTier = tier == .free ? .standard : .premium
        if remaining <= 0 {
            return "Upgrade to \(nextTier.displayName) for \(nextTier.monthlyMinutes) minutes/month and better voice quality."
        } else {
            return "Upgrade to \(nextTier.displayName) for more minutes and premium voice AI."
        }
    }
}
