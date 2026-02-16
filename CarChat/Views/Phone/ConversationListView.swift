import SwiftUI
import SwiftData

struct ConversationListView: View {
    let onResumeConversation: (Conversation) -> Void
    @Environment(AppServices.self) private var appServices
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    @State private var emptyStateVisible = false
    @State private var conversationToDelete: Conversation?

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
            .confirmationDialog(
                "Delete Conversation?",
                isPresented: Binding(
                    get: { conversationToDelete != nil },
                    set: { if !$0 { conversationToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        Haptics.thud()
                        withAnimation {
                            appServices.conversationStore.delete(conversation)
                        }
                        conversationToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    conversationToDelete = nil
                }
            } message: {
                Text("This conversation will be permanently deleted.")
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: CarChatTheme.Spacing.lg) {
            // Animated icon
            ZStack {
                // Breathing glow
                Circle()
                    .fill(CarChatTheme.Colors.glowCyan)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(emptyStateVisible ? 0.5 : 0.2)

                GradientIcon(
                    systemName: "bubble.left.and.bubble.right",
                    gradient: CarChatTheme.Gradients.accent,
                    size: 72,
                    iconSize: 30,
                    glowColor: CarChatTheme.Colors.glowCyan,
                    isAnimated: true
                )
            }
            .scaleEffect(emptyStateVisible ? 1.0 : 0.8)
            .opacity(emptyStateVisible ? 1.0 : 0)
            .accessibilityHidden(true)

            VStack(spacing: CarChatTheme.Spacing.xs) {
                Text(Microcopy.EmptyState.historyTitle)
                    .font(CarChatTheme.Typography.title)
                    .foregroundStyle(CarChatTheme.Colors.textPrimary)

                Text(Microcopy.EmptyState.historySubtitle)
                    .font(CarChatTheme.Typography.body)
                    .foregroundStyle(CarChatTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CarChatTheme.Spacing.xxxl)
            }
            .opacity(emptyStateVisible ? 1.0 : 0)
            .offset(y: emptyStateVisible ? 0 : 10)
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(CarChatTheme.Animation.smooth.delay(0.2)) {
                emptyStateVisible = true
            }
        }
    }

    @ViewBuilder
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: CarChatTheme.Spacing.sm) {
                ForEach(Array(conversations.enumerated()), id: \.element.id) { index, conversation in
                    ConversationRow(conversation: conversation)
                        .onTapGesture {
                            Haptics.tap()
                            onResumeConversation(conversation)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                conversationToDelete = conversation
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .scrollTransition(.animated.threshold(.visible(0.9))) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1 : 0.96)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .sensoryFeedback(.selection, trigger: conversation.id)
                }
            }
            .padding(.horizontal, CarChatTheme.Spacing.md)
            .padding(.top, CarChatTheme.Spacing.sm)
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        Haptics.thud()
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(conversation.displayTitle), \(conversation.personaName)")
        .accessibilityHint("Opens conversation")
    }
}
