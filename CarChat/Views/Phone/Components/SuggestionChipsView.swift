import SwiftUI

struct SuggestionChipsView: View {
    let suggestions: [PromptSuggestions.Suggestion]
    let onTap: (PromptSuggestions.Suggestion) -> Void

    @State private var appeared = false

    private let chipColors: [Color] = [
        CarChatTheme.Colors.accentGradientStart,
        CarChatTheme.Colors.listening,
        CarChatTheme.Colors.speaking,
        CarChatTheme.Colors.processing
    ]

    var body: some View {
        VStack(spacing: CarChatTheme.Spacing.lg) {
            HStack(spacing: CarChatTheme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CarChatTheme.Colors.accentGradientStart)

                Text("Try one of these")
                    .font(CarChatTheme.Typography.callout)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
            .opacity(appeared ? 1 : 0)

            VStack(spacing: CarChatTheme.Spacing.md) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    let tint = chipColors[index % chipColors.count]

                    Button {
                        Haptics.tap()
                        onTap(suggestion)
                    } label: {
                        HStack(spacing: CarChatTheme.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm, style: .continuous)
                                    .fill(tint.opacity(0.20))
                                    .frame(width: 34, height: 34)

                                Image(systemName: suggestion.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(tint)
                            }

                            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxxs) {
                                Text(suggestion.text)
                                    .font(CarChatTheme.Typography.body.weight(.semibold))
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                    .lineLimit(2)

                                Text("Tap to ask")
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(tint.opacity(0.9))
                                .padding(8)
                                .background(
                                    Circle().fill(tint.opacity(0.15))
                                )
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.lg)
                        .padding(.vertical, CarChatTheme.Spacing.sm + 2)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: CarChatTheme.Radius.lg,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(SuggestionChipButtonStyle(tint: tint))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.12),
                        value: appeared
                    )
                    .accessibilityLabel(suggestion.text)
                    .accessibilityHint("Sends this as a conversation starter")
                }
            }
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

private struct SuggestionChipButtonStyle: ButtonStyle {
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                CarChatTheme.Colors.surfaceGlass.opacity(configuration.isPressed ? 0.95 : 0.85),
                                CarChatTheme.Colors.surfaceSecondary.opacity(configuration.isPressed ? 0.80 : 0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                tint.opacity(configuration.isPressed ? 0.75 : 0.55),
                                Color.white.opacity(configuration.isPressed ? 0.18 : 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: configuration.isPressed ? 1.2 : 0.9
                    )
            )
            .shadow(
                color: tint.opacity(configuration.isPressed ? 0.18 : 0.30),
                radius: configuration.isPressed ? 8 : 14,
                x: 0,
                y: configuration.isPressed ? 4 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(reduceMotion ? nil : CarChatTheme.Animation.fast, value: configuration.isPressed)
    }
}
