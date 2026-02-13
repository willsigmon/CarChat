import SwiftUI

struct WelcomeStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("CarChat")
                .font(.largeTitle.bold())

            Text("Voice-first AI conversations\nbuilt for the road.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "mic.fill",
                    title: "Talk Naturally",
                    description: "Like a phone call with AI"
                )
                FeatureRow(
                    icon: "car.fill",
                    title: "CarPlay Ready",
                    description: "Designed for your car stereo"
                )
                FeatureRow(
                    icon: "sparkles",
                    title: "Multiple AI Providers",
                    description: "OpenAI, Claude, Gemini, Grok & more"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue") {
                viewModel.advance()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 48)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
