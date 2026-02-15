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
                    .strokeBorder(
                        CarChatTheme.Colors.surfaceBorder.opacity(0.75),
                        lineWidth: 0.75
                    )
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

// MARK: - Action Pill Button Style

enum CarChatActionPillTone: Sendable {
    case danger
    case accent
}

struct CarChatActionPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let tone: CarChatActionPillTone

    private var foreground: Color {
        switch tone {
        case .danger: .white
        case .accent: CarChatTheme.Colors.accentGradientStart
        }
    }

    private var fillGradient: LinearGradient {
        switch tone {
        case .danger:
            LinearGradient(
                colors: [
                    CarChatTheme.Colors.error.opacity(0.65),
                    CarChatTheme.Colors.error.opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .accent:
            LinearGradient(
                colors: [
                    CarChatTheme.Colors.surfaceGlass,
                    CarChatTheme.Colors.surfaceSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var border: Color {
        switch tone {
        case .danger: CarChatTheme.Colors.error.opacity(0.35)
        case .accent: CarChatTheme.Colors.accentGradientStart.opacity(0.35)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .padding(.horizontal, CarChatTheme.Spacing.sm)
            .padding(.vertical, CarChatTheme.Spacing.xxs + 1)
            .background(
                Capsule()
                    .fill(fillGradient)
                    .overlay(
                        Capsule().strokeBorder(border, lineWidth: 0.7)
                    )
            )
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
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

extension ButtonStyle where Self == CarChatActionPillButtonStyle {
    static func carChatActionPill(
        tone: CarChatActionPillTone
    ) -> CarChatActionPillButtonStyle {
        .init(tone: tone)
    }
}
