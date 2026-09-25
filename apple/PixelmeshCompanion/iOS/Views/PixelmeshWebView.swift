import SwiftUI
import WebKit

public struct PixelmeshWebView: UIViewRepresentable {
    public let url: URL
    public let bridgeCoordinator: BridgeCoordinator

    public init(url: URL, bridgeCoordinator: BridgeCoordinator) {
        self.url = url
        self.bridgeCoordinator = bridgeCoordinator
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // Injected bridge script hooks incoming WebSocket messages before app.js runs
        let bridgeScript = """
        (function() {
            window.__PIXELMESH_NATIVE__ = true;
            const origWS = window.WebSocket;
            if (origWS) {
                window.WebSocket = function(...args) {
                    const ws = new origWS(...args);
                    ws.addEventListener('message', function(event) {
                        try {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.pixelmeshBridge) {
                                window.webkit.messageHandlers.pixelmeshBridge.postMessage(event.data);
                            }
                        } catch (e) {
                            console.error("Bridge dispatch error", e);
                        }
                    });
                    return ws;
                };
            }
        })();
        """

        let userScript = WKUserScript(
            source: bridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.add(bridgeCoordinator, name: "pixelmeshBridge")
        config.userContentController = contentController

        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = bridgeCoordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        bridgeCoordinator.onNavigationFailed = { [weak webView] in
            loadOfflineFallback(into: webView)
        }

        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4.0))
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadOfflineFallback(into webView: WKWebView?) {
        guard let webView = webView else { return }
        if let offlineUrl = Bundle.main.url(forResource: "offline_mock", withExtension: "html") {
            webView.loadFileURL(offlineUrl, allowingReadAccessTo: offlineUrl.deletingLastPathComponent())
        }
    }
}
