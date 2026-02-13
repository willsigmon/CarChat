import SwiftUI

struct VoiceWaveformView: View {
    let level: Float
    private let barCount = 40

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        level: level,
                        index: index,
                        totalBars: barCount
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .padding(.horizontal, 24)
    }
}

private struct WaveformBar: View {
    let level: Float
    let index: Int
    let totalBars: Int

    var body: some View {
        let center = Double(totalBars) / 2.0
        let distance = abs(Double(index) - center) / center
        let baseHeight = 0.1
        let amplitude = Double(max(level, 0)) * (1.0 - distance * 0.6)
        let height = baseHeight + amplitude * 0.9

        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor.opacity(0.6 + amplitude * 0.4))
            .frame(maxHeight: .infinity)
            .scaleEffect(y: height, anchor: .center)
            .animation(
                .easeInOut(duration: 0.08),
                value: level
            )
    }
}
