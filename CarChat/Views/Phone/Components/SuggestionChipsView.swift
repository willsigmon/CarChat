import SwiftUI

struct SuggestionChipsView: View {
    let suggestions: [PromptSuggestions.Suggestion]
    let onTap: (PromptSuggestions.Suggestion) -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: CarChatTheme.Spacing.lg) {
            Text("Try saying...")
                .font(CarChatTheme.Typography.callout)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: CarChatTheme.Spacing.md) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    Button {
                        Haptics.tap()
                        onTap(suggestion)
                    } label: {
                        HStack(spacing: CarChatTheme.Spacing.sm) {
                            Image(systemName: suggestion.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                                .frame(width: 28)

                            Text(suggestion.text)
                                .font(CarChatTheme.Typography.body)
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.lg)
                        .padding(.vertical, CarChatTheme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.md)
                    }
                    .buttonStyle(.plain)
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
