import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(AppServices.self) private var appServices
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    var body: some View {
        NavigationStack {
            ZStack {
                CarChatTheme.Colors.background.ignoresSafeArea()

                Group {
                    if conversations.isEmpty {
                        emptyState
                    } else {
                        conversationList
                    }
                }
            }
            .navigationTitle("History")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: CarChatTheme.Spacing.md) {
            GradientIcon(
                systemName: "bubble.left.and.bubble.right",
                gradient: CarChatTheme.Gradients.accent,
                size: 64,
                iconSize: 28,
                glowColor: CarChatTheme.Colors.glowCyan
            )

            Text("No Conversations")
                .font(CarChatTheme.Typography.title)
                .foregroundStyle(CarChatTheme.Colors.textPrimary)

            Text("Start talking to create your first conversation.")
                .font(CarChatTheme.Typography.body)
                .foregroundStyle(CarChatTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CarChatTheme.Spacing.xxxl)
        }
    }

    @ViewBuilder
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: CarChatTheme.Spacing.sm) {
                ForEach(conversations) { conversation in
                    ConversationRow(conversation: conversation)
                }
            }
            .padding(.horizontal, CarChatTheme.Spacing.md)
            .padding(.top, CarChatTheme.Spacing.sm)
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            appServices.conversationStore.delete(conversations[index])
        }
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        GlassCard(cornerRadius: CarChatTheme.Radius.md, padding: CarChatTheme.Spacing.sm) {
            HStack(spacing: CarChatTheme.Spacing.sm) {
                // Provider icon
                ProviderIcon(provider: conversation.provider, size: 36)

                VStack(alignment: .leading, spacing: CarChatTheme.Spacing.xxs) {
                    Text(conversation.displayTitle)
                        .font(CarChatTheme.Typography.headline)
                        .foregroundStyle(CarChatTheme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: CarChatTheme.Spacing.xs) {
                        Text(conversation.personaName)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.accentGradientStart)

                        Circle()
                            .fill(CarChatTheme.Colors.textTertiary)
                            .frame(width: 3, height: 3)

                        Text(conversation.updatedAt, style: .relative)
                            .font(CarChatTheme.Typography.caption)
                            .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
            }
        }
    }
}
