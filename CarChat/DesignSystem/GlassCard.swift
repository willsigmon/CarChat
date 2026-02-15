import SwiftUI

// MARK: - Glass Card

/// Frosted glass card effect for the Midnight Dashboard theme
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat = CarChatTheme.Radius.lg,
        padding: CGFloat = CarChatTheme.Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
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
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.30))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                CarChatTheme.Colors.borderStrong.opacity(0.66),
                                CarChatTheme.Colors.borderMedium.opacity(0.40),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
    }
}

// MARK: - Glass Background Modifier

struct GlassBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                CarChatTheme.Colors.surfaceGlass.opacity(0.90),
                                CarChatTheme.Colors.surfaceSecondary.opacity(0.74)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.20))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        CarChatTheme.Colors.borderMedium.opacity(0.45),
                        lineWidth: 0.7
                    )
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = CarChatTheme.Radius.lg) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Glow Effect Modifier

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color : .clear, radius: radius)
            .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: radius * 1.5)
    }
}

extension View {
    func glow(
        color: Color = CarChatTheme.Colors.glowCyan,
        radius: CGFloat = 12,
        isActive: Bool = true
    ) -> some View {
        modifier(GlowEffect(color: color, radius: radius, isActive: isActive))
    }
}
