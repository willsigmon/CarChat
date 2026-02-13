import SwiftUI

struct APIKeySettingsView: View {
    @Environment(AppServices.self) private var appServices
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        List {
            ForEach(AIProviderType.allCases) { provider in
                if provider.requiresAPIKey, let viewModel {
                    APIKeyRow(
                        provider: provider,
                        viewModel: viewModel
                    )
                } else if !provider.requiresAPIKey {
                    HStack {
                        Label(provider.displayName, systemImage: "server.rack")
                        Spacer()
                        Text("No key needed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("API Keys")
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(appServices: appServices)
            }
        }
    }
}

private struct APIKeyRow: View {
    let provider: AIProviderType
    @Bindable var viewModel: SettingsViewModel
    @State private var isEditing = false
    @State private var editedKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(provider.displayName)
                    .font(.headline)
                Spacer()
                statusBadge
            }

            if isEditing {
                HStack {
                    SecureField("API Key", text: $editedKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Save") {
                        viewModel.saveKey(
                            for: provider,
                            key: editedKey
                        )
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Button(hasKey ? "Update Key" : "Add Key") {
                    editedKey = viewModel.apiKeys[provider] ?? ""
                    isEditing = true
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var hasKey: Bool {
        let key = viewModel.apiKeys[provider] ?? ""
        return !key.isEmpty
    }

    @ViewBuilder
    private var statusBadge: some View {
        if hasKey {
            Label("Configured", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        } else {
            Label("Not Set", systemImage: "xmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
