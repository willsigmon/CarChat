import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ConversationView()
                .tabItem {
                    Label("Talk", systemImage: "mic.fill")
                }

            ConversationListView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
