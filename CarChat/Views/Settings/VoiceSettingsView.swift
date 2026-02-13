import SwiftUI

struct VoiceSettingsView: View {
    @AppStorage("ttsEngine") private var ttsEngine = TTSEngineType.system.rawValue

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CarChatTheme.Spacing.md) {
                    // TTS Engine section
                    VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                        Text("TEXT-TO-SPEECH ENGINE")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            .padding(.horizontal, CarChatTheme.Spacing.xs)

                        ForEach(TTSEngineType.allCases) { engine in
                            TTSEngineCard(
                                engine: engine,
                                isSelected: engine.rawValue == ttsEngine
                            ) {
                                ttsEngine = engine.rawValue
                            }
                        }
                    }

                    // VAD section
                    VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xs) {
                        Text("VOICE ACTIVITY DETECTION")
                            .font(CarChatTheme.Typography.micro)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                            .padding(.horizontal, CarChatTheme.Spacing.xs)

                        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                            HStack(spacing: CarChatTheme.Spacing.sm) {
                                LayeredFeatureIcon(
                                    systemName: "waveform.badge.mic",
                                    color: CarChatTheme.Colors.listening,
                                    accentShape: .ring
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-Detect Silence")
                                        .font(CarChatTheme.Typography.headline)
                                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                                    Text("Automatically detects when you stop speaking.")
                                        .font(CarChatTheme.Typography.caption)
                                        .foregroundStyle(CarChatTheme.Colors.textTertiary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, CarChatTheme.Spacing.md)
                .padding(.top, CarChatTheme.Spacing.sm)
            }
        }
        .navigationTitle("Voice")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - TTS Engine Card

private struct TTSEngineCard: View {
    let engine: TTSEngineType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
                HStack(spacing: CarChatTheme.Spacing.sm) {
                    LayeredFeatureIcon(
                        systemName: "speaker.wave.2.fill",
                        color: isSelected
                            ? CarChatTheme.Colors.accentGradientStart
                            : CarChatTheme.Colors.textTertiary,
                        accentShape: .none
                    )

                    Text(engine.displayName)
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
