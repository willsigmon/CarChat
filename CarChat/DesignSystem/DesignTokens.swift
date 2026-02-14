import SwiftUI

// MARK: - Design Tokens

/// CarChat "Midnight Dashboard" design system
/// Inspired by luxury car cockpit interfaces — deep blacks, electric accents, glass surfaces
enum CarChatTheme {

    // MARK: - Colors

    enum Colors {
        // Brand
        static let accent = Color("AccentCyan")
        static let accentGradientStart = Color(hex: 0x00D4FF)
        static let accentGradientEnd = Color(hex: 0x0066FF)

        // Surfaces
        static let background = Color(hex: 0x0A0A0F)
        static let surfacePrimary = Color.white.opacity(0.06)
        static let surfaceSecondary = Color.white.opacity(0.03)
        static let surfaceGlass = Color.white.opacity(0.08)
        static let surfaceBorder = Color.white.opacity(0.10)

        // Borders
        static let borderSubtle = Color.white.opacity(0.06)
        static let borderMedium = Color.white.opacity(0.12)
        static let borderStrong = Color.white.opacity(0.20)

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.60)
        static let textTertiary = Color.white.opacity(0.45)

        // State Colors
        static let listening = Color(hex: 0x00E676)
        static let processing = Color(hex: 0xFFAB00)
        static let speaking = Color(hex: 0x448AFF)
        static let error = Color(hex: 0xFF5252)
        static let success = Color(hex: 0x00E676)

        // Glow Colors
        static let glowCyan = Color(hex: 0x00D4FF).opacity(0.30)
        static let glowGreen = Color(hex: 0x00E676).opacity(0.30)
        static let glowAmber = Color(hex: 0xFFAB00).opacity(0.30)
        static let glowBlue = Color(hex: 0x448AFF).opacity(0.30)
        static let glowRed = Color(hex: 0xFF5252).opacity(0.30)

        // Provider brand colors
        static func providerColor(_ provider: AIProviderType) -> Color {
            switch provider {
            case .openAI: Color(hex: 0x10A37F)
            case .anthropic: Color(hex: 0xD4A574)
            case .gemini: Color(hex: 0x4285F4)
            case .grok: Color(hex: 0xFFFFFF)
            case .ollama: Color(hex: 0x888888)
            }
        }
    }

    // MARK: - Gradients

    enum Gradients {
        static let accent = LinearGradient(
            colors: [Colors.accentGradientStart, Colors.accentGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let listening = LinearGradient(
            colors: [Color(hex: 0x00E676), Color(hex: 0x00BFA5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let processing = LinearGradient(
            colors: [Color(hex: 0xFFAB00), Color(hex: 0xFF6D00)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let speaking = LinearGradient(
            colors: [Color(hex: 0x448AFF), Color(hex: 0x7C4DFF)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let error = LinearGradient(
            colors: [Color(hex: 0xFF5252), Color(hex: 0xD50000)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        @available(iOS 18.0, *)
        static let ambientMesh = MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(hex: 0x0A0A0F), Color(hex: 0x0A0A0F), Color(hex: 0x0A0A0F),
                Color(hex: 0x001122), Color(hex: 0x001133), Color(hex: 0x0A0A0F),
                Color(hex: 0x0A0A0F), Color(hex: 0x000D1A), Color(hex: 0x0A0A0F)
            ]
        )
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 56
        static let massive: CGFloat = 80
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: - Animation

    enum Animation {
        static let micro = SwiftUI.Animation.easeOut(duration: 0.15)
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.8)
        static let breathe = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        static let springy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }

    // MARK: - Typography

    enum Typography {
        static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.bold)
        static let headline = Font.system(.headline).weight(.semibold)
        static let body = Font.system(.subheadline)
        static let callout = Font.system(.footnote).weight(.medium)
        static let caption = Font.system(.caption).weight(.medium)
        static let micro = Font.system(size: 10, weight: .semibold)

        static let statusLabel = Font.system(.footnote, design: .rounded).weight(.semibold)
            .monospacedDigit()
        static let transcriptUser = Font.system(.body).weight(.medium)
        static let transcriptAssistant = Font.system(.subheadline)
    }

    // MARK: - Shadows

    enum Shadows {
        static let glow = Shadow(color: Colors.glowCyan, radius: 20, x: 0, y: 0)
        static let subtle = Shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        static let elevated = Shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let hero: CGFloat = 48
        static let feature: CGFloat = 56
    }
}

// MARK: - Shadow helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
