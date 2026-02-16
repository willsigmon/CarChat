import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppServices.self) private var appServices
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier = .standard
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showContent = false

    var body: some View {
        NavigationStack {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CarChatTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: CarChatTheme.Spacing.sm) {
                            Text("Upgrade Your Voice")
                                .font(CarChatTheme.Typography.heroTitle)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)

                            Text("Better voice, smarter AI, more minutes")
                                .font(CarChatTheme.Typography.body)
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        }
                        .padding(.top, CarChatTheme.Spacing.xl)
                        .opacity(showContent ? 1 : 0)

                        // Tier cards
                        VStack(spacing: CarChatTheme.Spacing.md) {
                            TierCard(
                                tier: .free,
                                isSelected: selectedTier == .free,
                                product: nil,
                                onSelect: { selectedTier = .free }
                            )

                            TierCard(
                                tier: .standard,
                                isSelected: selectedTier == .standard,
                                product: appServices.storeManager.product(for: "carchat.standard.monthly"),
                                badge: "Most Popular",
                                onSelect: { selectedTier = .standard }
                            )

                            TierCard(
                                tier: .premium,
                                isSelected: selectedTier == .premium,
                                product: appServices.storeManager.product(for: "carchat.premium.monthly"),
                                onSelect: { selectedTier = .premium }
                            )
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .opacity(showContent ? 1 : 0)

                        // Error
                        if let purchaseError {
                            Text(purchaseError)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, CarChatTheme.Spacing.xl)
                        }

                        // CTA
                        VStack(spacing: CarChatTheme.Spacing.sm) {
                            if selectedTier != .free {
                                Button {
                                    Task { await purchaseSelected() }
                                } label: {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Subscribe to \(selectedTier.displayName)")
                                    }
                                }
                                .buttonStyle(.carChatPrimary)
                                .disabled(isPurchasing)
                            }

                            Button("Restore Purchases") {
                                Task { await appServices.storeManager.restorePurchases() }
                            }
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                        .padding(.bottom, CarChatTheme.Spacing.xxl)
                        .opacity(showContent ? 1 : 0)

                        // Credit packs
                        if !appServices.storeManager.creditProducts.isEmpty {
                            CreditPackSection(
                                products: appServices.storeManager.creditProducts,
                                onPurchase: { product in
                                    Task { await purchaseCredit(product) }
                                }
                            )
                            .padding(.horizontal, CarChatTheme.Spacing.md)
                            .opacity(showContent ? 1 : 0)
                        }

                        // Legal
                        VStack(spacing: CarChatTheme.Spacing.xs) {
                            Text("Subscriptions auto-renew monthly. Cancel anytime in Settings.")
                                .font(CarChatTheme.Typography.micro)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                        .padding(.bottom, CarChatTheme.Spacing.xxxl)
                    }
                }
            }
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                }
            }
        }
        .task {
            if appServices.storeManager.products.isEmpty {
                await appServices.storeManager.loadProducts()
            }
        }
        .onAppear {
            selectedTier = appServices.effectiveTier == .free ? .standard : appServices.effectiveTier
            withAnimation(CarChatTheme.Animation.smooth.delay(0.1)) {
                showContent = true
            }
        }
    }

    private func purchaseSelected() async {
        let productID: String
        switch selectedTier {
        case .standard: productID = "carchat.standard.monthly"
        case .premium: productID = "carchat.premium.monthly"
        default: return
        }

        guard let product = appServices.storeManager.product(for: productID) else {
            purchaseError = "Product not available"
            return
        }

        isPurchasing = true
        purchaseError = nil

        do {
            if let _ = try await appServices.storeManager.purchase(product) {
                Haptics.success()
                dismiss()
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            Haptics.error()
        }

        isPurchasing = false
    }

    private func purchaseCredit(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil

        do {
            if let _ = try await appServices.storeManager.purchase(product) {
                Haptics.success()
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            Haptics.error()
        }

        isPurchasing = false
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let product: Product?
    var badge: String?
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            onSelect()
        }) {
            GlassCard(cornerRadius: CarChatTheme.Radius.lg, padding: CarChatTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: CarChatTheme.Spacing.xs) {
                                Text(tier.displayName)
                                    .font(CarChatTheme.Typography.title)
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                if let badge {
                                    Text(badge)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(CarChatTheme.Colors.accentGradientStart)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(tier.voiceQualityDescription)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        }

                        Spacer()

                        priceLabel
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(tier.features, id: \.self) { feature in
                            HStack(spacing: CarChatTheme.Spacing.xs) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(isSelected ? CarChatTheme.Colors.accentGradientStart : CarChatTheme.Colors.textTertiary)

                                Text(feature)
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                    .stroke(
                        isSelected ? CarChatTheme.Colors.accentGradientStart : .clear,
                        lineWidth: 2
                    )
            )
        }
        .accessibilityLabel("\(tier.displayName) plan")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select")
    }

    @ViewBuilder
    private var priceLabel: some View {
        if let product {
            VStack(alignment: .trailing) {
                Text(product.displayPrice)
                    .font(CarChatTheme.Typography.title)
                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                Text("/month")
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
        } else {
            Text("Free")
                .font(CarChatTheme.Typography.title)
                .foregroundStyle(CarChatTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Credit Pack Section

private struct CreditPackSection: View {
    let products: [Product]
    let onPurchase: (Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
            Text("MINUTE PACKS")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .padding(.horizontal, CarChatTheme.Spacing.xs)

            ForEach(products, id: \.id) { product in
                GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName)
                                .font(CarChatTheme.Typography.headline)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)

                            Text(product.description)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        }

                        Spacer()

                        Button(product.displayPrice) {
                            Haptics.tap()
                            onPurchase(product)
                        }
                        .font(CarChatTheme.Typography.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .padding(.vertical, CarChatTheme.Spacing.xs)
                        .background(CarChatTheme.Gradients.accent)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
