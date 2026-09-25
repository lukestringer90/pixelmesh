import SwiftUI

public struct WatchLocatedView: View {
    public let blinkId: Int
    @State private var breathe = false

    public init(blinkId: Int) {
        self.blinkId = blinkId
    }

    public var body: some View {
        ZStack {
            (breathe ? Color(red: 0.0, green: 0.90, blue: 0.46) : Color(red: 0.0, green: 0.62, blue: 0.32))
                .ignoresSafeArea()
                .animation(.linear(duration: 4.0).repeatForever(autoreverses: true), value: breathe)

            VStack(spacing: 4) {
                Spacer()
                Text("Found you")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.15, blue: 0.07))

                Text("PHONE #\(blinkId + 1)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(red: 0.0, green: 0.15, blue: 0.07).opacity(0.65))
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            breathe = true
        }
    }
}

#Preview {
    WatchLocatedView(blinkId: 41)
}
