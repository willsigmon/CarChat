import SwiftUI

struct PermissionsStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("Permissions")
                .font(.title.bold())

            Text("CarChat needs microphone and speech recognition to have voice conversations.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 16) {
                PermissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "Capture your voice",
                    isGranted: viewModel.hasMicPermission
                )
                PermissionRow(
                    icon: "waveform",
                    title: "Speech Recognition",
                    description: "Transcribe your speech",
                    isGranted: viewModel.hasSpeechPermission
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button("Grant Permissions") {
                    viewModel.requestPermissions()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Continue") {
                    viewModel.advance()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool

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

            Image(
                systemName: isGranted
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(isGranted ? .green : .secondary)
        }
    }
}
