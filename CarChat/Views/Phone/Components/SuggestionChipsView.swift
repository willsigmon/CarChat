import SwiftUI

struct SuggestionChipsView: View {
    let suggestions: [PromptSuggestions.Suggestion]
    let onTap: (PromptSuggestions.Suggestion) -> Void
    let onRefresh: (() -> Void)?

    @State private var appeared = false

    private let chipColors: [Color] = [
        CarChatTheme.Colors.accentGradientStart,
        CarChatTheme.Colors.listening,
        CarChatTheme.Colors.speaking,
        CarChatTheme.Colors.processing
    ]
    private let gridColumns = [
        GridItem(.flexible(), spacing: CarChatTheme.Spacing.md),
        GridItem(.flexible(), spacing: CarChatTheme.Spacing.md)
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
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: CarChatTheme.Spacing.md) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    let tint = chipColors[index % chipColors.count]

                    Button {
                        Haptics.tap()
                        onTap(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm, style: .continuous)
                                        .fill(tint.opacity(0.20))
                                        .frame(width: 34, height: 34)

                                    Image(systemName: suggestion.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(tint)
                                }

                                Spacer(minLength: 0)
                            }

                            VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxxs) {
                                Text(suggestion.text)
                                    .font(CarChatTheme.Typography.body.weight(.semibold))
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("Tap to ask")
                                    .font(CarChatTheme.Typography.caption)
                                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.md)
                        .padding(.vertical, CarChatTheme.Spacing.sm)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 112, alignment: .topLeading)
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
                            .delay(Double(index) * 0.07),
                        value: appeared
                    )
                    .accessibilityLabel(suggestion.text)
                    .accessibilityHint("Sends this as a conversation starter")
                }
                }

                if let onRefresh {
                    Button {
                        Haptics.tap()
                        onRefresh()
                    } label: {
                        Label("More ideas", systemImage: "arrow.clockwise")
                            .font(CarChatTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(CarChatTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.carChatActionPill(tone: .accent))
                    .padding(.top, CarChatTheme.Spacing.xs)
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
