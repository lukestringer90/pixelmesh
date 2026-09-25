import SwiftUI
import Observation
import WatchKit
import PixelmeshCore

@Observable
public final class WatchStateManager: NSObject, @unchecked Sendable {
    public var envelope: WatchMeshEnvelope = .unpairedDefault
    private var extendedSession: WKExtendedRuntimeSession?
    private var debugCycleIndex: Int = 0

    public override init() {
        super.init()
    }

    public func startSession() {
        WatchConnectivityReceiver.shared.onEnvelopeReceived = { [weak self] newEnvelope in
            Task { @MainActor in
                self?.envelope = newEnvelope
                self?.evaluateExtendedSession()
            }
        }
        WatchConnectivityReceiver.shared.activate()
    }

    private func evaluateExtendedSession() {
        if envelope.pairing.isPaired && extendedSession == nil {
            extendedSession = WKExtendedRuntimeSession()
            extendedSession?.delegate = self
            extendedSession?.start()
        } else if !envelope.pairing.isPaired {
            extendedSession?.invalidate()
            extendedSession = nil
        }
    }

    // MARK: - Standalone Debug Cycling (#if DEBUG)

    public func cycleDebugState() {
        debugCycleIndex = (debugCycleIndex + 1) % 4
        switch debugCycleIndex {
        case 0:
            envelope = .mockUnpaired
        case 1:
            envelope = .mockWaiting
        case 2:
            envelope = .mockLocated
        case 3:
            envelope = .mockWave
        default:
            envelope = .mockUnpaired
        }
        evaluateExtendedSession()
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate
extension WatchStateManager: WKExtendedRuntimeSessionDelegate {
    public func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        extendedSession = nil
    }

    public func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    public func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}
}
