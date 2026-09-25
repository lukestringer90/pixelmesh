import Foundation

public struct EffectShaderEvaluator: Sendable {
    public static func directedCoord(u: Double, v: Double, angleDeg: Double) -> Double {
        let a = angleDeg * .pi / 180.0
        let raw = u * cos(a) + v * sin(a)
        return (raw + 1.0) / 2.0
    }

    public static func evaluate(
        effect: EffectParameters,
        u: Double,
        v: Double,
        nowMs: Double
    ) -> RGBColor {
        guard effect.name == "wave" else {
            return .black
        }

        let t = max(0.0, (nowMs - effect.startTime) / 1000.0)
        let d = directedCoord(u: u, v: v, angleDeg: effect.angle)

        // Wave formula from public/app.js:1534-1536
        let phase = 2.0 * .pi * (d * effect.spatialFreq - t * effect.speed)
        let intensity = 0.5 + 0.5 * sin(phase)

        return RGBColor(
            r: intensity * effect.colorR,
            g: intensity * effect.colorG,
            b: intensity * effect.colorB
        )
    }
}
