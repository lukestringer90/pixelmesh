import SwiftUI
import PixelmeshCore

public struct ContentView: View {
    @Environment(WatchStateManager.self) private var state

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !state.envelope.pairing.isPaired {
                UnpairedView()
            } else {
                switch state.envelope.viewState {
                case .unpaired:
                    UnpairedView()
                case .waiting:
                    WatchWaitingView(blinkId: state.envelope.pairing.blinkId)
                case .located:
                    WatchLocatedView(blinkId: state.envelope.pairing.blinkId ?? 0)
                case .effects:
                    if let effect = state.envelope.activeEffect {
                        WatchEffectRenderView(
                            effect: effect,
                            u: state.envelope.pairing.u,
                            v: state.envelope.pairing.v,
                            serverOffset: state.envelope.serverTimeOffsetMs
                        )
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                }
            }
        }
        #if DEBUG
        // Triple-tap to cycle state during standalone simulator or watch testing
        .onTapGesture(count: 3) {
            state.cycleDebugState()
        }
        #endif
    }
}

#Preview("Unpaired") {
    ContentView()
        .environment({
            let m = WatchStateManager()
            m.envelope = .mockUnpaired
            return m
        }())
}

#Preview("Waiting") {
    ContentView()
        .environment({
            let m = WatchStateManager()
            m.envelope = .mockWaiting
            return m
        }())
}

#Preview("Located") {
    ContentView()
        .environment({
            let m = WatchStateManager()
            m.envelope = .mockLocated
            return m
        }())
}

#Preview("Wave Effect") {
    ContentView()
        .environment({
            let m = WatchStateManager()
            m.envelope = .mockWave
            return m
        }())
}
