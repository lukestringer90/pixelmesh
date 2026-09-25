import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

public struct RGBColor: Equatable, Sendable, Codable {
    public let r: Double
    public let g: Double
    public let b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = min(max(r, 0.0), 255.0)
        self.g = min(max(g, 0.0), 255.0)
        self.b = min(max(b, 0.0), 255.0)
    }

    public static let black = RGBColor(r: 0, g: 0, b: 0)
    public static let white = RGBColor(r: 255, g: 255, b: 255)

    #if canImport(SwiftUI)
    public var swiftUIColor: Color {
        Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
    }
    #endif
}
