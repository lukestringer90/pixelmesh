import SwiftUI

public struct UnpairedView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 32))
                .foregroundStyle(.cyan)
            Text("open pixelmesh")
                .font(.headline)
            Text("Launch on iPhone to pair")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    UnpairedView()
}
