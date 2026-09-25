import Foundation
import WatchConnectivity
import PixelmeshCore

public final class WatchConnectivityReceiver: NSObject, WCSessionDelegate, @unchecked Sendable {
    public static let shared = WatchConnectivityReceiver()

    public var onEnvelopeReceived: ((WatchMeshEnvelope) -> Void)?

    private override init() {
        super.init()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        if let envelope = WatchMeshEnvelope(from: message) {
            onEnvelopeReceived?(envelope)
        }
    }

    public func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        if let envelope = WatchMeshEnvelope(from: applicationContext) {
            onEnvelopeReceived?(envelope)
        }
    }
}
