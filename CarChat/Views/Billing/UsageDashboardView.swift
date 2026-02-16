import SwiftUI

struct UsageDashboardView: View {
    @Environment(AppServices.self) private var appServices
    @State private var showContent = false

    private var tier: SubscriptionTier { appServices.effectiveTier }
    private var remaining: Int { appServices.usageTracker.remainingMinutes }
    private var total: Int { tier.monthlyMinutes }
    private var used: Int { max(0, total - remaining) }
    private var progress: Double {
        guard total > 0, total != .max else { return 0 }
        return Double(used) / Double(total)
    }

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.xl) {
                    // Circular usage gauge
                    usageGauge
                        .padding(.top, CarChatTheme.Spacing.xl)
                        .opacity(showContent ? 1 : 0)

                    // Current plan info
                    planInfoCard
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .opacity(showContent ? 1 : 0)

                    // Usage breakdown
                    usageBreakdownCard
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .opacity(showContent ? 1 : 0)

                    // Upgrade CTA (only for free/standard)
                    if tier == .free || tier == .standard {
                        upgradeCard
                            .padding(.horizontal, CarChatTheme.Spacing.md)
                            .opacity(showContent ? 1 : 0)
                    }
                }
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
            }
        }
        .navigationTitle("Usage")
        .onAppear {
            withAnimation(CarChatTheme.Animation.smooth.delay(0.1)) {
                showContent = true
            }
        }
        .task {
            await appServices.usageTracker.refreshQuota(tier: tier)
        }
    }

    // MARK: - Usage Gauge

    private var usageGauge: some View {
        VStack(spacing: CarChatTheme.Spacing.md) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        CarChatTheme.Colors.surfaceBorder,
                        lineWidth: 12
                    )
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        gaugeGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(CarChatTheme.Animation.smooth, value: progress)

                // Center text
                VStack(spacing: 2) {
                    if tier == .byok {
                        Image(systemName: "infinity")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)
                    } else {
                        Text("\(remaining)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)
                            .contentTransition(.numericText())
                    }

                    Text("min left")
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }
            }

            if tier != .byok {
                Text("\(used) of \(total) minutes used this month")
                    .font(CarChatTheme.Typography.body)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tier == .byok
            ? "Unlimited usage, Power User mode"
            : "\(remaining) minutes remaining out of \(total)")
    }

    private var gaugeGradient: AngularGradient {
        let color: Color = progress > 0.85
            ? CarChatTheme.Colors.error
            : progress > 0.6
                ? CarChatTheme.Colors.processing
                : CarChatTheme.Colors.accentGradientStart

        return AngularGradient(
            colors: [color.opacity(0.5), color],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress)
        )
    }

    // MARK: - Plan Info

    private var planInfoCard: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.lg, padding: CarChatTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    Text(tier.displayName)
                        .font(CarChatTheme.Typography.title)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Voice Quality")
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)

                    Text(tier.voiceQualityDescription)
                        .font(CarChatTheme.Typography.callout)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    // MARK: - Usage Breakdown

    private var usageBreakdownCard: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.lg, padding: CarChatTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                Text("This Month")
                    .font(CarChatTheme.Typography.headline)
                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                UsageRow(
                    label: "Minutes Used",
                    value: tier == .byok ? "--" : "\(used)",
                    icon: "clock",
                    color: CarChatTheme.Colors.accentGradientStart
                )

                UsageRow(
                    label: "Sessions",
                    value: "\(appServices.usageTracker.sessionCount)",
                    icon: "bubble.left.and.bubble.right",
                    color: CarChatTheme.Colors.speaking
                )

                UsageRow(
                    label: "Max Session",
                    value: tier == .byok ? "Unlimited" : "\(tier.maxSessionMinutes) min",
                    icon: "timer",
                    color: CarChatTheme.Colors.processing
                )
            }
        }
    }

    // MARK: - Upgrade Card

    private var upgradeCard: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.lg, padding: CarChatTheme.Spacing.md) {
            VStack(spacing: CarChatTheme.Spacing.sm) {
                let nextTier: SubscriptionTier = tier == .free ? .standard : .premium

                Text("Upgrade to \(nextTier.displayName)")
                    .font(CarChatTheme.Typography.headline)
                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                Text(nextTier.voiceQualityDescription)
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)

                Button("View Plans") {
                    Haptics.tap()
                }
                .buttonStyle(.carChatPrimary)
            }
        }
    }
}

// MARK: - Usage Row

private struct UsageRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: CarChatTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(CarChatTheme.Typography.body)
                .foregroundStyle(CarChatTheme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(CarChatTheme.Typography.headline)
                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                .monospacedDigit()
        }
    }
}
