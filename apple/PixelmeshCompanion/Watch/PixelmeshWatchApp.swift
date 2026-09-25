import SwiftUI

@main
struct PixelmeshWatchApp: App {
    @State private var stateManager = WatchStateManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stateManager)
                .onAppear {
                    stateManager.startSession()
                }
        }
    }
}
