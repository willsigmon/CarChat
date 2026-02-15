import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .talk

    enum Tab: String {
        case talk, history, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationView()
                .tabItem {
                    Label("Talk", systemImage: "mic.fill")
                }
                .tag(Tab.talk)
                .accessibilityLabel("Talk")
                .accessibilityHint("Start a voice conversation")

            ConversationListView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)
                .accessibilityLabel("History")
                .accessibilityHint("View past conversations")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
                .accessibilityLabel("Settings")
                .accessibilityHint("Configure app settings")
        }
        .tint(CarChatTheme.Colors.accentGradientStart)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
