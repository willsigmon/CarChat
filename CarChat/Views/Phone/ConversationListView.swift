import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(AppServices.self) private var appServices
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start talking to create your first conversation.")
                    )
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            ConversationRow(conversation: conversation)
                        }
                        .onDelete(perform: deleteConversations)
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            appServices.conversationStore.delete(conversations[index])
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(conversation.provider.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(conversation.personaName)
                    .font(.caption)
                    .foregroundStyle(.blue)

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
