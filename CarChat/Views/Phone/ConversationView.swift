import SwiftUI

struct ConversationView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: ConversationViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VoiceWaveformView(level: viewModel?.audioLevel ?? 0)
                    .frame(height: 200)

                if let transcript = viewModel?.currentTranscript, !transcript.isEmpty {
                    Text(transcript)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                Spacer()

                MicButton(
                    isListening: viewModel?.isListening ?? false
                ) {
                    viewModel?.toggleListening()
                }
                .padding(.bottom, 48)
            }
            .navigationTitle("CarChat")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel == nil {
                    viewModel = ConversationViewModel(
                        appServices: appServices
                    )
                }
            }
        }
    }
}
