import SwiftUI
import SwiftData

struct PersonaSettingsView: View {
    @Query(sort: \Persona.createdAt) private var personas: [Persona]

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            if personas.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: CarChatTheme.Spacing.sm) {
                        ForEach(personas) { persona in
                            PersonaCard(persona: persona)
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.md)
                    .padding(.top, CarChatTheme.Spacing.sm)
                }
            }
        }
        .navigationTitle("Personas")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: CarChatTheme.Spacing.md) {
            GradientIcon(
                systemName: "person.crop.circle.badge.plus",
                gradient: CarChatTheme.Gradients.accent,
                size: 64,
                iconSize: 28,
                glowColor: CarChatTheme.Colors.glowCyan
            )

            Text("No Personas")
                .font(CarChatTheme.Typography.title)
                .foregroundStyle(CarChatTheme.Colors.textPrimary)

            Text("The default Sigmon persona will be created on first launch.")
                .font(CarChatTheme.Typography.body)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CarChatTheme.Spacing.xxxl)
        }
    }
}

// MARK: - Persona Card

private struct PersonaCard: View {
    let persona: Persona

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
            HStack(spacing: CarChatTheme.Spacing.sm) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(CarChatTheme.Colors.accentGradientStart.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    CarChatTheme.Colors.accentGradientStart.opacity(0.3),
                                    lineWidth: 0.5
                                )
                        )

                    Text(String(persona.name.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                }

                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxs) {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Text(persona.name)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        if persona.isDefault {
                            Text("Default")
                                .font(CarChatTheme.Typography.micro)
                                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(CarChatTheme.Colors.accentGradientStart.opacity(0.12))
                                )
                        }
                    }

                    Text(persona.personality)
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
    }
}
