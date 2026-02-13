import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("AI Providers") {
                    NavigationLink("API Keys") {
                        APIKeySettingsView()
                    }
                }

                Section("Voice") {
                    NavigationLink("Voice Settings") {
                        VoiceSettingsView()
                    }
                }

                Section("Personas") {
                    NavigationLink("Manage Personas") {
                        PersonaSettingsView()
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(
                            Bundle.main.infoDictionary?[
                                "CFBundleShortVersionString"
                            ] as? String ?? "1.0"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
