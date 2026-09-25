import Foundation

public enum ViewState: String, Codable, Sendable {
    case unpaired
    case waiting
    case located
    case effects
}

public struct PairingState: Codable, Sendable, Equatable {
    public var isPaired: Bool
    public var deviceId: String?
    public var blinkId: Int?
    public var u: Double
    public var v: Double
    public var calibrated: Bool

    public init(
        isPaired: Bool = false,
        deviceId: String? = nil,
        blinkId: Int? = nil,
        u: Double = 0.5,
        v: Double = 0.5,
        calibrated: Bool = false
    ) {
        self.isPaired = isPaired
        self.deviceId = deviceId
        self.blinkId = blinkId
        self.u = u
        self.v = v
        self.calibrated = calibrated
    }

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "isPaired": isPaired,
            "u": u,
            "v": v,
            "calibrated": calibrated
        ]
        if let deviceId = deviceId { dict["deviceId"] = deviceId }
        if let blinkId = blinkId { dict["blinkId"] = blinkId }
        return dict
    }

    public init?(from dictionary: [String: Any]) {
        self.isPaired = dictionary["isPaired"] as? Bool ?? false
        self.deviceId = dictionary["deviceId"] as? String
        self.blinkId = dictionary["blinkId"] as? Int
        self.u = (dictionary["u"] as? NSNumber)?.doubleValue ?? 0.5
        self.v = (dictionary["v"] as? NSNumber)?.doubleValue ?? 0.5
        self.calibrated = dictionary["calibrated"] as? Bool ?? false
    }
}

public struct WatchMeshEnvelope: Codable, Sendable, Equatable {
    public var version: Int
    public var timestamp: Double
    public var serverTimeOffsetMs: Double
    public var pairing: PairingState
    public var viewState: ViewState
    public var activeEffect: EffectParameters?

    public init(
        version: Int = 1,
        timestamp: Double = Date().timeIntervalSince1970 * 1000.0,
        serverTimeOffsetMs: Double = 0.0,
        pairing: PairingState = PairingState(),
        viewState: ViewState = .unpaired,
        activeEffect: EffectParameters? = nil
    ) {
        self.version = version
        self.timestamp = timestamp
        self.serverTimeOffsetMs = serverTimeOffsetMs
        self.pairing = pairing
        self.viewState = viewState
        self.activeEffect = activeEffect
    }

    public static var unpairedDefault: WatchMeshEnvelope {
        WatchMeshEnvelope(
            version: 1,
            pairing: PairingState(isPaired: false),
            viewState: .unpaired
        )
    }

    // MARK: - Debug & Preview Presets

    public static var mockUnpaired: WatchMeshEnvelope {
        unpairedDefault
    }

    public static var mockWaiting: WatchMeshEnvelope {
        WatchMeshEnvelope(
            pairing: PairingState(
                isPaired: true,
                deviceId: "mock-phone-uuid",
                blinkId: 41, // 0-indexed ID 41 -> Phone #42
                u: 0.5,
                v: 0.5,
                calibrated: false
            ),
            viewState: .waiting
        )
    }

    public static var mockLocated: WatchMeshEnvelope {
        WatchMeshEnvelope(
            pairing: PairingState(
                isPaired: true,
                deviceId: "mock-phone-uuid",
                blinkId: 41,
                u: 0.5,
                v: 0.5,
                calibrated: true
            ),
            viewState: .located
        )
    }

    public static var mockWave: WatchMeshEnvelope {
        WatchMeshEnvelope(
            pairing: PairingState(
                isPaired: true,
                deviceId: "mock-phone-uuid",
                blinkId: 41,
                u: 0.5,
                v: 0.5,
                calibrated: true
            ),
            viewState: .effects,
            activeEffect: EffectParameters(
                name: "wave",
                startTime: (Date().timeIntervalSince1970 - 2.0) * 1000.0,
                speed: 0.4,
                spatialFreq: 1.5,
                bpm: 100.0,
                angle: 0.0,
                colorR: 0.0,
                colorG: 220.0,
                colorB: 255.0
            )
        )
    }

    // MARK: - Serialization

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "version": version,
            "timestamp": timestamp,
            "serverTimeOffsetMs": serverTimeOffsetMs,
            "pairing": pairing.toDictionary(),
            "viewState": viewState.rawValue
        ]
        if let activeEffect = activeEffect {
            dict["activeEffect"] = activeEffect.toDictionary()
        }
        return dict
    }

    public init?(from dictionary: [String: Any]) {
        self.version = dictionary["version"] as? Int ?? 1
        self.timestamp = (dictionary["timestamp"] as? NSNumber)?.doubleValue ?? 0.0
        self.serverTimeOffsetMs = (dictionary["serverTimeOffsetMs"] as? NSNumber)?.doubleValue ?? 0.0

        if let pairingDict = dictionary["pairing"] as? [String: Any],
           let parsedPairing = PairingState(from: pairingDict) {
            self.pairing = parsedPairing
        } else {
            self.pairing = PairingState()
        }

        if let stateRaw = dictionary["viewState"] as? String,
           let parsedState = ViewState(rawValue: stateRaw) {
            self.viewState = parsedState
        } else {
            self.viewState = self.pairing.isPaired ? .waiting : .unpaired
        }

        if let effectDict = dictionary["activeEffect"] as? [String: Any] {
            self.activeEffect = EffectParameters(from: effectDict)
        } else {
            self.activeEffect = nil
        }
    }
}
