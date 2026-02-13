import SwiftUI

struct OnboardingContainerView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        Group {
            if let viewModel {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStepView(viewModel: viewModel)
                case .permissions:
                    PermissionsStepView(viewModel: viewModel)
                case .apiKey:
                    APIKeyStepView(viewModel: viewModel)
                case .ready:
                    ReadyStepView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(appServices: appServices)
            }
        }
    }
}

private struct ReadyStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle.bold())

            Text("Tap the mic to start your first conversation.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Get Started") {
                viewModel.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 48)
        }
    }
}
