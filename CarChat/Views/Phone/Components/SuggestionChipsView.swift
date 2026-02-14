import SwiftUI

struct SuggestionChipsView: View {
    let suggestions: [PromptSuggestions.Suggestion]
    let onTap: (PromptSuggestions.Suggestion) -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: CarChatTheme.Spacing.xs) {
            Text("Try saying...")
                .font(CarChatTheme.Typography.micro)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: CarChatTheme.Spacing.xs) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    Button {
                        Haptics.tap()
                        onTap(suggestion)
                    } label: {
                        HStack(spacing: CarChatTheme.Spacing.xs) {
                            Image(systemName: suggestion.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                                .frame(width: 20)

                            Text(suggestion.text)
                                .font(CarChatTheme.Typography.caption)
                                .foregroundStyle(CarChatTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, CarChatTheme.Spacing.sm)
                        .padding(.vertical, CarChatTheme.Spacing.xs)
                        .glassBackground(cornerRadius: CarChatTheme.Radius.pill)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
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
