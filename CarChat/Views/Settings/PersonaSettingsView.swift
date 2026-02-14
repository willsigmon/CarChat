import SwiftUI
import SwiftData

struct PersonaSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Persona.createdAt) private var personas: [Persona]
    @State private var editingPersona: Persona?

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            if personas.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: CarChatTheme.Spacing.sm) {
                        ForEach(personas) { persona in
                            PersonaCard(
                                persona: persona,
                                onSetDefault: { setDefault(persona) },
                                onEdit: { editingPersona = persona }
                            )
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.md)
                    .padding(.top, CarChatTheme.Spacing.sm)
                }
            }
        }
        .navigationTitle("Personas")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $editingPersona) { persona in
            PersonaEditSheet(persona: persona)
                .preferredColorScheme(.dark)
        }
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
            .accessibilityHidden(true)

            Text("No Personas")
                .font(CarChatTheme.Typography.title)
                .foregroundStyle(CarChatTheme.Colors.textPrimary)

            Text("The default Sigmon persona will be created on first launch.")
                .font(CarChatTheme.Typography.body)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CarChatTheme.Spacing.xxxl)
        }
        .accessibilityElement(children: .combine)
    }

    private func setDefault(_ persona: Persona) {
        Haptics.success()
        // Clear existing defaults
        for p in personas {
            p.isDefault = false
        }
        persona.isDefault = true
        try? modelContext.save()
    }
}

// MARK: - Persona Card

private struct PersonaCard: View {
    let persona: Persona
    let onSetDefault: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
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
                                StatusBadge(
                                    text: "Default",
                                    color: CarChatTheme.Colors.accentGradientStart
                                )
                            }
                        }

                        Text(persona.personality)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if !persona.isDefault {
                        Button {
                            onSetDefault()
                        } label: {
                            Text("Set Default")
                                .font(CarChatTheme.Typography.micro)
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                                .padding(.horizontal, CarChatTheme.Spacing.xs)
                                .padding(.vertical, CarChatTheme.Spacing.xxs)
                                .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
                        }
                        .accessibilityLabel("Set \(persona.name) as default")
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(persona.name)\(persona.isDefault ? ", default persona" : ""). \(persona.personality)")
        .accessibilityHint("Tap to edit")
    }
}

// MARK: - Persona Edit Sheet

private struct PersonaEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let persona: Persona

    @State private var editedName: String = ""
    @State private var editedPersonality: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CarChatTheme.Spacing.md) {
                        // Name field
                        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                            Text("NAME")
                                .font(CarChatTheme.Typography.micro)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                .padding(.horizontal, CarChatTheme.Spacing.xs)
                                .accessibilityAddTraits(.isHeader)

                            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                TextField("Persona name", text: $editedName)
                                    .font(CarChatTheme.Typography.headline)
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                    .tint(CarChatTheme.Colors.accentGradientStart)
                            }
                        }

                        // Personality field
                        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                            Text("PERSONALITY")
                                .font(CarChatTheme.Typography.micro)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                .padding(.horizontal, CarChatTheme.Spacing.xs)
                                .accessibilityAddTraits(.isHeader)

                            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                                TextField("Describe the personality...", text: $editedPersonality, axis: .vertical)
                                    .font(CarChatTheme.Typography.body)
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                    .lineLimit(3...8)
                                    .tint(CarChatTheme.Colors.accentGradientStart)
                            }
                        }
                    }
                    .padding(.horizontal, CarChatTheme.Spacing.md)
                    .padding(.top, CarChatTheme.Spacing.sm)
                }
            }
            .navigationTitle("Edit Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            editedName = persona.name
            editedPersonality = persona.personality
        }
    }

    private func saveChanges() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        persona.name = trimmedName
        persona.personality = editedPersonality.trimmingCharacters(in: .whitespaces)
        Haptics.success()
        try? modelContext.save()
    }
}

// MARK: - Status Badge (Reusable)

struct StatusBadge: View {
    let text: String
    let color: Color
    var isActive: Bool = true

    var body: some View {
        HStack(spacing: CarChatTheme.Spacing.xxs) {
            if isActive {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }

            Text(text)
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}
