import SwiftUI

struct PermissionsStepView: View {
    let viewModel: OnboardingViewModel

    private var allGranted: Bool {
        viewModel.hasMicPermission && viewModel.hasSpeechPermission
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: allGranted ? "checkmark.shield.fill" : "shield.checkered")
                .font(.system(size: 60))
                .foregroundStyle(allGranted ? Color.green : Color.accentColor)
                .contentTransition(.symbolEffect(.replace))

            Text(allGranted ? "All Set!" : "Permissions")
                .font(.title.bold())
                .contentTransition(.numericText())

            Text(
                allGranted
                    ? "Microphone and speech recognition are ready."
                    : "CarChat needs microphone and speech recognition to have voice conversations."
            )
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

            if allGranted {
                Button("Continue") {
                    viewModel.advance()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 48)
            } else {
                VStack(spacing: 12) {
                    Button("Grant Permissions") {
                        viewModel.requestPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip for Now") {
                        viewModel.advance()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 48)
            }
        }
        .animation(.default, value: allGranted)
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
                .foregroundStyle(isGranted ? Color.green : Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isGranted ? Color.green : Color.gray.opacity(0.3))
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isGranted ? Color.green.opacity(0.08) : Color(.secondarySystemBackground))
        )
        .animation(.default, value: isGranted)
    }
}
