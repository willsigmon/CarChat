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

                Text("Pick a quick prompt")
                    .font(CarChatTheme.Typography.callout)
                    .foregroundStyle(CarChatTheme.Colors.textSecondary)
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
                                HStack(spacing: CarChatTheme.Spacing.xxs) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: CarChatTheme.Radius.sm, style: .continuous)
                                            .fill(tint.opacity(0.20))
                                            .frame(width: 34, height: 34)

                                        Image(systemName: suggestion.icon)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(tint)
                                    }

                                    Spacer(minLength: 0)

                                    Text(suggestion.topic.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .tracking(0.7)
                                        .foregroundStyle(tint.opacity(0.95))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(tint.opacity(0.15))
                                        )
                                }

                                Text(suggestion.text)
                                    .font(CarChatTheme.Typography.body.weight(.semibold))
                                    .foregroundStyle(CarChatTheme.Colors.textPrimary)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: CarChatTheme.Spacing.xxxs)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.horizontal, CarChatTheme.Spacing.md)
                            .padding(.vertical, CarChatTheme.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .frame(height: 118, alignment: .topLeading)
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
                                CarChatTheme.Colors.surfacePrimary.opacity(configuration.isPressed ? 0.93 : 0.88),
                                CarChatTheme.Colors.surfaceGlass.opacity(configuration.isPressed ? 0.82 : 0.76)
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
                                tint.opacity(configuration.isPressed ? 0.46 : 0.32),
                                CarChatTheme.Colors.borderSubtle.opacity(configuration.isPressed ? 0.75 : 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: configuration.isPressed ? 1.1 : 0.8
                    )
            )
            .shadow(
                color: tint.opacity(configuration.isPressed ? 0.10 : 0.14),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .overlay(alignment: .bottom) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(configuration.isPressed ? 0.80 : 0.68),
                                tint.opacity(configuration.isPressed ? 0.24 : 0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .padding(.horizontal, CarChatTheme.Spacing.sm)
                    .padding(.bottom, CarChatTheme.Spacing.xs)
            }
            .scaleEffect(configuration.isPressed ? 0.976 : 1.0)
            .brightness(configuration.isPressed ? -0.015 : 0)
            .animation(
                reduceMotion
                    ? nil
                    : .interactiveSpring(response: 0.24, dampingFraction: 0.72, blendDuration: 0.12),
                value: configuration.isPressed
            )
    }
}
