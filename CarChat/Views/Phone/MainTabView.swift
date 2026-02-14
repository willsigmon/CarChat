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

            ConversationListView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(CarChatTheme.Colors.accentGradientStart)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
