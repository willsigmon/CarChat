import SwiftUI

struct TopicCategoryCard: View {
    let category: TopicCategory

    var body: some View {
        VStack(alignment: .leading, spacing: CarChatTheme.Spacing.sm) {
            HStack(spacing: CarChatTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                Spacer()

                Text("\(category.promptCount)")
                    .font(CarChatTheme.Typography.micro)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(CarChatTheme.Typography.headline)
                    .foregroundStyle(CarChatTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(category.subcategories.count) topics")
                    .font(CarChatTheme.Typography.caption)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
        }
        .padding(CarChatTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            CarChatTheme.Colors.surfaceGlass.opacity(0.94),
                            CarChatTheme.Colors.surfaceSecondary.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                        .fill(.ultraThinMaterial.opacity(0.30))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CarChatTheme.Radius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            category.color.opacity(0.25),
                            CarChatTheme.Colors.borderMedium.opacity(0.40),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(category.promptCount) prompts")
        .accessibilityHint("Opens topic category")
    }
}
