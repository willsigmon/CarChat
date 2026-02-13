import SwiftUI

struct ConversationView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: ConversationViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    VStack(spacing: 0) {
                        Spacer()

                        VoiceWaveformView(level: viewModel.audioLevel)
                            .frame(height: 200)

                        if !viewModel.currentTranscript.isEmpty {
                            Text(viewModel.currentTranscript)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .transition(.opacity)
                        }

                        Spacer()

                        MicButton(
                            isListening: viewModel.isListening
                        ) {
                            viewModel.toggleListening()
                        }
                        .padding(.bottom, 48)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("CarChat")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = ConversationViewModel(appServices: appServices)
                }
            }
        }
    }
}
