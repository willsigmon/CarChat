import SwiftUI
import AuthenticationServices

struct SignInStepView: View {
    let viewModel: OnboardingViewModel
    @Environment(AppServices.self) private var appServices
    @State private var showContent = false
    @State private var isSigningIn = false
    @State private var signInError: String?

    var body: some View {
        ZStack {
            CarChatTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: CarChatTheme.Spacing.xxl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(CarChatTheme.Colors.glowCyan)
                        .frame(width: 100, height: 100)
                        .blur(radius: 25)
                        .opacity(0.4)

                    GradientIcon(
                        systemName: "person.crop.circle.badge.checkmark",
                        gradient: CarChatTheme.Gradients.accent,
                        size: 80,
                        iconSize: 36,
                        glowColor: CarChatTheme.Colors.glowCyan,
                        isAnimated: false
                    )
                }
                .opacity(showContent ? 1 : 0)

                VStack(spacing: CarChatTheme.Spacing.sm) {
                    Text("Save Your Conversations")
                        .font(CarChatTheme.Typography.heroTitle)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)

                    Text("Sign in to sync across devices and unlock your full history")
                        .font(CarChatTheme.Typography.body)
                        .foregroundStyle(CarChatTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CarChatTheme.Spacing.xxl)
                }
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Error message
                if let signInError {
                    Text(signInError)
                        .font(CarChatTheme.Typography.caption)
                        .foregroundStyle(CarChatTheme.Colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CarChatTheme.Spacing.xl)
                }

                // Sign in with Apple
                VStack(spacing: CarChatTheme.Spacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: CarChatTheme.Radius.md))
                    .disabled(isSigningIn)
                    .opacity(isSigningIn ? 0.6 : 1.0)

                    Button("Skip for Now") {
                        Haptics.tap()
                        viewModel.advance()
                    }
                    .font(CarChatTheme.Typography.headline)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                }
                .padding(.horizontal, CarChatTheme.Spacing.xl)
                .padding(.bottom, CarChatTheme.Spacing.xxxl)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(CarChatTheme.Animation.smooth.delay(0.2)) {
                showContent = true
            }
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8)
            else {
                signInError = "Failed to get Apple ID credentials"
                return
            }

            isSigningIn = true
            signInError = nil

            Task {
                do {
                    // Generate nonce for Supabase auth
                    try await appServices.authManager.signInWithApple(
                        idToken: tokenString,
                        nonce: "" // Supabase handles nonce internally
                    )
                    Haptics.success()
                    viewModel.advance()
                } catch {
                    signInError = "Sign in failed: \(error.localizedDescription)"
                    Haptics.error()
                }
                isSigningIn = false
            }

        case .failure(let error):
            // User cancelled or other error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                signInError = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }
}
