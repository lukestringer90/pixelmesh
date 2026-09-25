import SwiftUI

public struct WatchWaitingView: View {
    public let blinkId: Int?

    public init(blinkId: Int? = nil) {
        self.blinkId = blinkId
    }

    public var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 8, height: 8)

            Text("pixelmesh")
                .font(.system(size: 16, weight: .bold))

            Text("Get ready")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            if let blinkId = blinkId {
                Text("PHONE #\(blinkId + 1)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
}

#Preview {
    WatchWaitingView(blinkId: 41)
}
