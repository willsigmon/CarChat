import SwiftUI

struct APIKeyStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("Connect an AI Provider")
                .font(.title.bold())

            Text("Enter an API key to get started.\nYou can add more providers later.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 16) {
                Picker("Provider", selection: $viewModel.selectedProvider) {
                    ForEach(
                        AIProviderType.allCases.filter(\.requiresAPIKey)
                    ) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                SecureField("API Key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Continue") {
                    viewModel.advance()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.apiKey.isEmpty)

                Button("Skip for Now") {
                    viewModel.advance()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)
        }
    }
}
