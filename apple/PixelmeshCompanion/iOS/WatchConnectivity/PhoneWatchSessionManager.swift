import Foundation
import WatchConnectivity
import PixelmeshCore

@MainActor
public final class PhoneWatchSessionManager: NSObject, ObservableObject {
    public static let shared = PhoneWatchSessionManager()

    @Published public private(set) var currentEnvelope: WatchMeshEnvelope = .unpairedDefault
    @Published public private(set) var isWatchAppInstalled: Bool = false
    @Published public private(set) var isWatchReachable: Bool = false

    private var session: WCSession?

    private override init() {
        super.init()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    public func processWebEvent(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        processWebJson(json)
    }

    public func simulateWebEvent(_ json: [String: Any]) {
        processWebJson(json)
    }

    private func processWebJson(_ json: [String: Any]) {
        guard let type = json["type"] as? String else { return }
        var mutated = false

        switch type {
        case "assigned":
            currentEnvelope.pairing.isPaired = true
            currentEnvelope.pairing.deviceId = json["device_id"] as? String ?? currentEnvelope.pairing.deviceId
            currentEnvelope.pairing.blinkId = json["blink_id"] as? Int
            currentEnvelope.pairing.u = (json["u"] as? NSNumber)?.doubleValue ?? 0.5
            currentEnvelope.pairing.v = (json["v"] as? NSNumber)?.doubleValue ?? 0.5
            currentEnvelope.pairing.calibrated = json["calibrated"] as? Bool ?? false
            currentEnvelope.viewState = currentEnvelope.pairing.calibrated ? .located : .waiting
            mutated = true

        case "update_position":
            currentEnvelope.pairing.u = (json["u"] as? NSNumber)?.doubleValue ?? currentEnvelope.pairing.u
            currentEnvelope.pairing.v = (json["v"] as? NSNumber)?.doubleValue ?? currentEnvelope.pairing.v
            currentEnvelope.pairing.calibrated = true
            currentEnvelope.viewState = .located
            mutated = true

        case "mode":
            if let mode = json["mode"] as? String {
                if mode == "SHOWTIME" {
                    currentEnvelope.viewState = .effects
                    mutated = true
                }
            }

        case "effect":
            currentEnvelope.viewState = .effects
            currentEnvelope.activeEffect = EffectParameters(from: json)
            mutated = true

        case "effect_stop":
            currentEnvelope.activeEffect = nil
            currentEnvelope.viewState = currentEnvelope.pairing.calibrated ? .located : .waiting
            mutated = true

        case "sync_pong":
            if let serverTime = (json["server_time"] as? NSNumber)?.doubleValue,
               let clientTime = (json["client_time"] as? NSNumber)?.doubleValue {
                let localNow = Date().timeIntervalSince1970 * 1000.0
                let rtt = localNow - clientTime
                // Reject jitter outliers
                if rtt <= 150.0 {
                    let estimatedServerNow = serverTime + (rtt / 2.0)
                    currentEnvelope.serverTimeOffsetMs = estimatedServerNow - localNow
                    mutated = true
                }
            }

        case "reset":
            currentEnvelope.activeEffect = nil
            currentEnvelope.pairing.calibrated = false
            currentEnvelope.viewState = currentEnvelope.pairing.isPaired ? .waiting : .unpaired
            mutated = true

        default:
            break
        }

        if mutated {
            currentEnvelope.timestamp = Date().timeIntervalSince1970 * 1000.0
            dispatchToWatch()
        }
    }

    public func dispatchToWatch() {
        guard let session = session, session.activationState == .activated else {
            return
        }

        let payload = currentEnvelope.toDictionary()

        // If the watch is reachable, send message instantaneously
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak session] _ in
                // Fall back to application context on transfer error
                try? session?.updateApplicationContext(payload)
            }
        } else {
            // Background or sleeping watch fallback
            try? session.updateApplicationContext(payload)
        }
    }
}

// MARK: - WCSessionDelegate
extension PhoneWatchSessionManager: WCSessionDelegate {
    public nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isWatchReachable = session.isReachable
            if activationState == .activated {
                self.dispatchToWatch()
            }
        }
    }

    public nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    public nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    public nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    public nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isWatchReachable = session.isReachable
        }
    }
}
