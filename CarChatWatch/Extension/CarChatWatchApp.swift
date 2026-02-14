import SwiftUI

@main
struct CarChatWatchApp: App {
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self)
    private var extensionDelegate

    @StateObject private var viewModel = WatchConversationViewModel()

    var body: some Scene {
        WindowGroup {
            WatchConversationView(viewModel: viewModel)
        }
    }
}
