import SwiftUI
import PixelmeshCore

public struct WatchEffectRenderView: View {
    public let effect: EffectParameters
    public let u: Double
    public let v: Double
    public let serverOffset: Double

    public init(
        effect: EffectParameters,
        u: Double,
        v: Double,
        serverOffset: Double
    ) {
        self.effect = effect
        self.u = u
        self.v = v
        self.serverOffset = serverOffset
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let localTimeMs = timeline.date.timeIntervalSince1970 * 1000.0
            let adjustedNowMs = localTimeMs + serverOffset

            let rgb = EffectShaderEvaluator.evaluate(
                effect: effect,
                u: u,
                v: v,
                nowMs: adjustedNowMs
            )

            rgb.swiftUIColor
                .ignoresSafeArea()
        }
    }
}

#Preview {
    WatchEffectRenderView(
        effect: EffectParameters(
            name: "wave",
            startTime: Date().timeIntervalSince1970 * 1000.0,
            speed: 0.4,
            spatialFreq: 1.5,
            angle: 0.0,
            colorR: 0.0,
            colorG: 220.0,
            colorB: 255.0
        ),
        u: 0.5,
        v: 0.5,
        serverOffset: 0.0
    )
}
