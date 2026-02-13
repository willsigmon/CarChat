import SwiftUI

struct MicButton: View {
    let isListening: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.red : Color.accentColor)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (isListening ? Color.red : Color.accentColor)
                            .opacity(0.4),
                        radius: isListening ? 16 : 8
                    )

                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isListening ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isListening)
        .accessibilityLabel(
            isListening ? "Stop listening" : "Start listening"
        )
    }
}
