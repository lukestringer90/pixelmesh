import SwiftUI
import PixelmeshCore

@main
struct PixelmeshIOSApp: App {
    @StateObject private var watchManager = PhoneWatchSessionManager.shared
    @State private var serverHost: String = "http://localhost:16924"
    @State private var showDebugDrawer = false
    @State private var bridgeCoordinator = BridgeCoordinator()

    init() {
        PhoneWatchSessionManager.shared.activate()
        KeepAwakeService.shared.setKeepAwake(true)
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottomTrailing) {
                Color.black.ignoresSafeArea()

                if let url = URL(string: serverHost) {
                    PixelmeshWebView(url: url, bridgeCoordinator: bridgeCoordinator)
                        .ignoresSafeArea()
                }

                // Floating Debug Launcher (#if DEBUG)
                #if DEBUG
                Button {
                    showDebugDrawer = true
                } label: {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(12)
                        .background(Color.yellow)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
                #endif
            }
            .sheet(isPresented: $showDebugDrawer) {
                DebugDrawerView(watchManager: watchManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                showDebugDrawer = true
            }
        }
    }
}

// MARK: - Shake Detection Helper
extension NSNotification.Name {
    static let deviceDidShakeNotification = NSNotification.Name("PixelmeshDeviceDidShakeNotification")
}

#if canImport(UIKit)
import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
        }
    }
}
#endif
