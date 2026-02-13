import SwiftUI

struct VoiceSettingsView: View {
    @AppStorage("ttsEngine") private var ttsEngine = TTSEngineType.system.rawValue

    var body: some View {
        List {
            Section("Text-to-Speech Engine") {
                ForEach(TTSEngineType.allCases) { engine in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(engine.displayName)
                                .font(.body)
                        }
                        Spacer()
                        if engine.rawValue == ttsEngine {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        ttsEngine = engine.rawValue
                    }
                }
            }

            Section("Voice Activity Detection") {
                Text("Automatically detects when you stop speaking.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Voice")
    }
}
