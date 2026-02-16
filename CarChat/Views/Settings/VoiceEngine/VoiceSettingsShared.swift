import SwiftData
import SwiftUI

// MARK: - Shared View Builders for Voice Engine Sections

/// Reusable BYOK (Bring Your Own Key) card for API key entry.
struct BYOKKeyCard: View {
    let hasKey: Bool
    @Binding var isEditing: Bool
    @Binding var keyText: String
    let placeholder: String
    let providerURL: String
    let onSave: () -> Void

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: "key.fill",
                        color: CarChatTheme.Colors.accentGradientStart,
                        accentShape: .none
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("API Key")
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        Text(hasKey
                             ? "Your key is securely stored in Keychain"
                             : "Get one at \(providerURL)")
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }

                    Spacer()
                }

                if isEditing {
                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        HStack(spacing: CarChatTheme.Spacing.xs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)

                            SecureField(placeholder, text: $keyText)
                                .font(CarChatTheme.Typography.body)
                                .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .tint(CarChatTheme.Colors.accentGradientStart)
                        }
                        .padding(CarChatTheme.Spacing.xs)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.sm)

                        Button("Save") {
                            onSave()
                        }
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, CarChatTheme.Spacing.sm)
                        .padding(.vertical, CarChatTheme.Spacing.xs)
                        .background(Capsule().fill(CarChatTheme.Gradients.accent))
                    }
                } else {
                    Button(hasKey ? "Update Key" : "Add Key") {
                        isEditing = true
                    }
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                }
            }
        }
    }
}

/// Error card shown when voice listing fails.
struct VoiceErrorCard: View {
    let error: String

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
            HStack(spacing: CarChatTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CarChatTheme.Colors.error)
                Text(error)
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
            }
        }
    }
}

/// Button to trigger loading available voices from an API.
struct LoadVoicesButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                    Text("Load Available Voices")
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// A simple voice selection row with avatar initial, name, detail, and checkmark.
struct SimpleVoiceRow: View {
    let name: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(CarChatTheme.Animation.fast) {
                action()
            }
        } label: {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(CarChatTheme.Colors.speaking.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(CarChatTheme.Colors.speaking)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(CarChatTheme.Typography.headline)
                            .foregroundStyle(CarChatTheme.Colors.textPrimary)

                        if !detail.isEmpty {
                            Text(detail)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            isSelected
                                ? CarChatTheme.Colors.accentGradientStart
                                : CarChatTheme.Colors.textTertiary
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// Voice picker header with title and optional refresh / loading indicator.
struct VoicePickerHeader: View {
    let isLoading: Bool
    let hasVoices: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            Text("VOICE")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)

            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(CarChatTheme.Colors.accentGradientStart)
            } else if hasVoices {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, CarChatTheme.Spacing.xs)
    }
}

// MARK: - Persona Helper

/// Fetches the active (default) persona from the given model container.
@MainActor
func fetchActivePersona(from appServices: AppServices) -> Persona? {
    let context = appServices.modelContainer.mainContext
    let descriptor = FetchDescriptor<Persona>(
        predicate: #Predicate { $0.isDefault == true }
    )
    return (try? context.fetch(descriptor))?.first
}
