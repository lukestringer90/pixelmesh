import Foundation
import WebKit

@MainActor
public final class BridgeCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private let watchManager: PhoneWatchSessionManager
    public var onNavigationFailed: (() -> Void)?

    public init(watchManager: PhoneWatchSessionManager = .shared) {
        self.watchManager = watchManager
        super.init()
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "pixelmeshBridge" else { return }

        if let bodyString = message.body as? String,
           let data = bodyString.data(using: .utf8) {
            watchManager.processWebEvent(data: data)
        } else if let bodyDict = message.body as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: bodyDict) {
            watchManager.processWebEvent(data: data)
        }
    }

    // MARK: - WKNavigationDelegate

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // High-resilience auto-recovery if WebKit process is purged under memory pressure
        webView.reload()
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        // Remote host unreachable: invoke fallback callback
        onNavigationFailed?()
    }
}
