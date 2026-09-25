import UIKit

@MainActor
public final class KeepAwakeService {
    public static let shared = KeepAwakeService()

    private init() {}

    public func setKeepAwake(_ enabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = enabled
    }
}
