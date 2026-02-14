import SwiftUI

// MARK: - Primary Button Style

struct CarChatPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CarChatTheme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.md)
                    .fill(CarChatTheme.Gradients.accent)
                    .opacity(isEnabled ? 1.0 : 0.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.md)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(
                color: CarChatTheme.Colors.glowCyan,
                radius: configuration.isPressed ? 4 : 12
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(CarChatTheme.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct CarChatSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CarChatTheme.Typography.headline)
            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.md)
                    .fill(CarChatTheme.Colors.surfaceGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CarChatTheme.Radius.md)
                    .strokeBorder(
                        CarChatTheme.Colors.accentGradientStart.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(CarChatTheme.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style

struct CarChatGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CarChatTheme.Typography.callout)
            .foregroundStyle(CarChatTheme.Colors.textSecondary)
            .padding(.vertical, CarChatTheme.Spacing.xs)
            .padding(.horizontal, CarChatTheme.Spacing.md)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .animation(CarChatTheme.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - Convenience Extensions

extension ButtonStyle where Self == CarChatPrimaryButtonStyle {
    static var carChatPrimary: CarChatPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == CarChatSecondaryButtonStyle {
    static var carChatSecondary: CarChatSecondaryButtonStyle { .init() }
}

extension ButtonStyle where Self == CarChatGhostButtonStyle {
    static var carChatGhost: CarChatGhostButtonStyle { .init() }
}
