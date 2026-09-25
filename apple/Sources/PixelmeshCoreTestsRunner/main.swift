import Foundation
import PixelmeshCore

struct TestFailure: Error {
    let message: String
}

func assertCondition(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw TestFailure(message: message)
    }
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw TestFailure(message: "\(message): expected \(expected), got \(actual)")
    }
}

func assertDoubleEqual(_ actual: Double, _ expected: Double, tolerance: Double = 0.001, _ message: String) throws {
    if abs(actual - expected) > tolerance {
        throw TestFailure(message: "\(message): expected \(expected), got \(actual) (diff: \(abs(actual - expected)))")
    }
}

@main
struct PixelmeshCoreTestsRunner {
    static func main() {
        print("=== pixelmesh Core MVP Test Suite ===")
        var passed = 0
        var failed = 0

        func runTest(_ name: String, block: () throws -> Void) {
            do {
                try block()
                print("  [PASS] \(name)")
                passed += 1
            } catch {
                print("  [FAIL] \(name): \(error)")
                failed += 1
            }
        }

        // Test 1: Directed coordinate calculation
        runTest("testDirectedCoord") {
            // angle = 0 deg: raw = u * 1 + v * 0 = u -> (u + 1)/2
            let d0 = EffectShaderEvaluator.directedCoord(u: 0.0, v: 0.0, angleDeg: 0.0)
            try assertDoubleEqual(d0, 0.5, "d at u=0, angle=0 should be 0.5")

            let d1 = EffectShaderEvaluator.directedCoord(u: 1.0, v: 0.0, angleDeg: 0.0)
            try assertDoubleEqual(d1, 1.0, "d at u=1, angle=0 should be 1.0")

            let dMinus1 = EffectShaderEvaluator.directedCoord(u: -1.0, v: 0.0, angleDeg: 0.0)
            try assertDoubleEqual(dMinus1, 0.0, "d at u=-1, angle=0 should be 0.0")
        }

        // Test 2: Wave effect peak intensity
        runTest("testWavePeakAndIntensity") {
            let effect = EffectParameters(
                name: "wave",
                startTime: 1000.0,
                speed: 0.5,
                spatialFreq: 1.0,
                angle: 0.0,
                colorR: 200.0,
                colorG: 100.0,
                colorB: 50.0
            )

            // When phase = 0:
            // d = directedCoord(u, v, angle=0) = (u + 1)/2
            // Choose u=0 -> d=0.5. At t=1.0s:
            // phase = 2 * pi * (0.5 * 1.0 - 1.0 * 0.5) = 0
            // intensity = 0.5 + 0.5 * sin(0) = 0.5
            let midRgb = EffectShaderEvaluator.evaluate(
                effect: effect,
                u: 0.0,
                v: 0.0,
                nowMs: 2000.0 // t = 1.0s
            )
            try assertDoubleEqual(midRgb.r, 100.0, "r at phase 0 should be 100.0")
            try assertDoubleEqual(midRgb.g, 50.0, "g at phase 0 should be 50.0")
            try assertDoubleEqual(midRgb.b, 25.0, "b at phase 0 should be 25.0")

            // Test peak intensity = 1.0:
            // We want phase = pi/2 -> 2 * pi * (d * spatialFreq - t * speed) = pi/2
            // -> d * spatialFreq - t * speed = 0.25
            // With t=0, speed=0.5, spatialFreq=1.0 -> d = 0.25 -> (u + 1)/2 = 0.25 -> u = -0.5
            let peakRgb = EffectShaderEvaluator.evaluate(
                effect: effect,
                u: -0.5,
                v: 0.0,
                nowMs: 1000.0 // t = 0s
            )
            try assertDoubleEqual(peakRgb.r, 200.0, "peak r should be 200.0")
            try assertDoubleEqual(peakRgb.g, 100.0, "peak g should be 100.0")
            try assertDoubleEqual(peakRgb.b, 50.0, "peak b should be 50.0")
        }

        // Test 3: Non-wave effects fall back to black in MVP
        runTest("testNonWaveFallbackToBlack") {
            let effect = EffectParameters(name: "sparkle", colorR: 255.0, colorG: 255.0, colorB: 255.0)
            let rgb = EffectShaderEvaluator.evaluate(effect: effect, u: 0.5, v: 0.5, nowMs: 1500.0)
            try assertEqual(rgb, .black, "Non-wave effect in MVP must return RGBColor.black")
        }

        // Test 4: Envelope Dictionary Serialization Round-trip
        runTest("testEnvelopeSerializationRoundTrip") {
            let original = WatchMeshEnvelope(
                version: 1,
                timestamp: 1774384920000.0,
                serverTimeOffsetMs: -15.5,
                pairing: PairingState(
                    isPaired: true,
                    deviceId: "dev-abc-123",
                    blinkId: 14,
                    u: 0.35,
                    v: 0.85,
                    calibrated: true
                ),
                viewState: .effects,
                activeEffect: EffectParameters(
                    name: "wave",
                    startTime: 1774384918000.0,
                    speed: 0.4,
                    spatialFreq: 2.0,
                    angle: 45.0,
                    colorR: 0.0,
                    colorG: 180.0,
                    colorB: 255.0
                )
            )

            let dict = original.toDictionary()
            guard let restored = WatchMeshEnvelope(from: dict) else {
                throw TestFailure(message: "Failed to deserialize envelope dictionary")
            }

            try assertEqual(restored.version, original.version, "version matches")
            try assertDoubleEqual(restored.timestamp, original.timestamp, "timestamp matches")
            try assertDoubleEqual(restored.serverTimeOffsetMs, original.serverTimeOffsetMs, "offset matches")
            try assertEqual(restored.viewState, .effects, "viewState matches")
            try assertEqual(restored.pairing.isPaired, true, "isPaired matches")
            try assertEqual(restored.pairing.blinkId, 14, "blinkId matches")
            try assertDoubleEqual(restored.pairing.u, 0.35, "u matches")
            try assertDoubleEqual(restored.pairing.v, 0.85, "v matches")
            try assertEqual(restored.pairing.calibrated, true, "calibrated matches")
            try assertEqual(restored.activeEffect?.name, "wave", "effect name matches")
            try assertDoubleEqual(restored.activeEffect?.speed ?? 0, 0.4, "effect speed matches")
            try assertDoubleEqual(restored.activeEffect?.angle ?? 0, 45.0, "effect angle matches")
        }

        // Test 5: Mock Presets Validity
        runTest("testMockPresets") {
            let unpaired = WatchMeshEnvelope.mockUnpaired
            try assertEqual(unpaired.viewState, .unpaired, "mockUnpaired state")
            try assertEqual(unpaired.pairing.isPaired, false, "mockUnpaired pairing")

            let waiting = WatchMeshEnvelope.mockWaiting
            try assertEqual(waiting.viewState, .waiting, "mockWaiting state")
            try assertEqual(waiting.pairing.isPaired, true, "mockWaiting pairing")
            try assertEqual(waiting.pairing.calibrated, false, "mockWaiting calibrated")

            let located = WatchMeshEnvelope.mockLocated
            try assertEqual(located.viewState, .located, "mockLocated state")
            try assertEqual(located.pairing.calibrated, true, "mockLocated calibrated")
            try assertEqual(located.pairing.blinkId, 41, "mockLocated blinkId")

            let wave = WatchMeshEnvelope.mockWave
            try assertEqual(wave.viewState, .effects, "mockWave state")
            try assertEqual(wave.activeEffect?.name, "wave", "mockWave effect name")
        }

        print("\nTest Summary: \(passed) passed, \(failed) failed")
        if failed > 0 {
            exit(1)
        }
    }
}
