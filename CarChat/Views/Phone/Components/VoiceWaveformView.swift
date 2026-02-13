import SwiftUI

struct VoiceWaveformView: View {
    let level: Float
    let state: VoiceSessionState

    private let barCount = 48

    private var stateColor: Color {
        switch state {
        case .idle: CarChatTheme.Colors.accentGradientStart
        case .listening: CarChatTheme.Colors.listening
        case .processing: CarChatTheme.Colors.processing
        case .speaking: CarChatTheme.Colors.speaking
        case .error: CarChatTheme.Colors.error
        }
    }

    private var stateGradient: LinearGradient {
        switch state {
        case .idle: CarChatTheme.Gradients.accent
        case .listening: CarChatTheme.Gradients.listening
        case .processing: CarChatTheme.Gradients.processing
        case .speaking: CarChatTheme.Gradients.speaking
        case .error: CarChatTheme.Gradients.error
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Glow behind waveform
                if state.isActive {
                    RoundedRectangle(cornerRadius: CarChatTheme.Radius.xl)
                        .fill(stateColor.opacity(0.05))
                        .blur(radius: 20)
                        .frame(
                            width: geometry.size.width * 0.8,
                            height: geometry.size.height * 0.6
                        )
                }

                // Waveform bars
                HStack(spacing: 2.5) {
                    ForEach(0..<barCount, id: \.self) { index in
                        WaveformBar(
                            level: level,
                            index: index,
                            totalBars: barCount,
                            gradient: stateGradient,
                            isActive: state.isActive
                        )
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }
        }
        .padding(.horizontal, CarChatTheme.Spacing.xl)
        .animation(CarChatTheme.Animation.fast, value: state)
    }
}

private struct WaveformBar: View {
    let level: Float
    let index: Int
    let totalBars: Int
    let gradient: LinearGradient
    let isActive: Bool

    var body: some View {
        let center = Double(totalBars) / 2.0
        let distance = abs(Double(index) - center) / center
        let edgeFade = 1.0 - pow(distance, 1.5)
        let baseHeight = isActive ? 0.08 : 0.04
        let amplitude = Double(max(level, 0)) * edgeFade
        let height = baseHeight + amplitude * 0.85

        // Each bar has its own staggered "jitter" for organic feel
        let jitter = sin(Double(index) * 0.5 + Double(level) * 3.0) * 0.05

        RoundedRectangle(cornerRadius: 3)
            .fill(gradient)
            .opacity(isActive ? (0.4 + amplitude * 0.6) : 0.15)
            .frame(maxHeight: .infinity)
            .scaleEffect(y: max(baseHeight, height + jitter), anchor: .center)
            .animation(
                .easeInOut(duration: 0.06 + distance * 0.04),
                value: level
            )
    }
}
