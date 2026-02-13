import SwiftUI
import SwiftData

struct PersonaSettingsView: View {
    @Query(sort: \Persona.createdAt) private var personas: [Persona]

    var body: some View {
        List {
            ForEach(personas) { persona in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(persona.name)
                            .font(.headline)
                        if persona.isDefault {
                            Text("Default")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    Text(persona.personality)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 2)
            }

            if personas.isEmpty {
                ContentUnavailableView(
                    "No Personas",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("The default Sigmon persona will be created on first launch.")
                )
            }
        }
        .navigationTitle("Personas")
    }
}
