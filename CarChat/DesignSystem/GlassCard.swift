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
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
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
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        Color.white.opacity(0.08),
                        lineWidth: 0.5
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

// MARK: - Embossed Text

struct EmbossedText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .white.opacity(0.15), radius: 0, x: 0, y: 1)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: -1)
    }
}

extension View {
    func embossed() -> some View {
        modifier(EmbossedText())
    }
}

// MARK: - Glass Card Press Style

/// Button style that adds subtle press feedback to any view
struct GlassCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .brightness(configuration.isPressed ? 0.02 : 0)
            .animation(CarChatTheme.Animation.micro, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassCardButtonStyle {
    static var glassPress: GlassCardButtonStyle { .init() }
}
