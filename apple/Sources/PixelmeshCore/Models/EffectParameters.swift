import Foundation

public struct EffectParameters: Equatable, Sendable, Codable {
    public let name: String
    public let startTime: Double
    public let speed: Double
    public let spatialFreq: Double
    public let bpm: Double
    public let angle: Double
    public let originU: Double
    public let originV: Double
    public let colorR: Double
    public let colorG: Double
    public let colorB: Double
    public let color2R: Double
    public let color2G: Double
    public let color2B: Double

    public init(
        name: String,
        startTime: Double = 0.0,
        speed: Double = 0.3,
        spatialFreq: Double = 1.5,
        bpm: Double = 100.0,
        angle: Double = 0.0,
        originU: Double = 0.5,
        originV: Double = 0.5,
        colorR: Double = 255.0,
        colorG: Double = 255.0,
        colorB: Double = 255.0,
        color2R: Double = 255.0,
        color2G: Double = 0.0,
        color2B: Double = 0.0
    ) {
        self.name = name
        self.startTime = startTime
        self.speed = speed
        self.spatialFreq = spatialFreq
        self.bpm = bpm
        self.angle = angle
        self.originU = originU
        self.originV = originV
        self.colorR = colorR
        self.colorG = colorG
        self.colorB = colorB
        self.color2R = color2R
        self.color2G = color2G
        self.color2B = color2B
    }

    public init?(from dictionary: [String: Any]) {
        guard let name = dictionary["effect"] as? String ?? dictionary["name"] as? String else {
            return nil
        }
        self.name = name
        self.startTime = (dictionary["start_time"] as? NSNumber)?.doubleValue
            ?? (dictionary["startTime"] as? NSNumber)?.doubleValue
            ?? 0.0
        self.speed = (dictionary["speed"] as? NSNumber)?.doubleValue ?? 0.3
        self.spatialFreq = (dictionary["spatial_freq"] as? NSNumber)?.doubleValue
            ?? (dictionary["spatialFreq"] as? NSNumber)?.doubleValue
            ?? 1.5
        self.bpm = (dictionary["bpm"] as? NSNumber)?.doubleValue ?? 100.0
        self.angle = (dictionary["angle"] as? NSNumber)?.doubleValue
            ?? (dictionary["wave_angle"] as? NSNumber)?.doubleValue
            ?? 0.0
        self.originU = (dictionary["origin_u"] as? NSNumber)?.doubleValue
            ?? (dictionary["originU"] as? NSNumber)?.doubleValue
            ?? 0.5
        self.originV = (dictionary["origin_v"] as? NSNumber)?.doubleValue
            ?? (dictionary["originV"] as? NSNumber)?.doubleValue
            ?? 0.5
        self.colorR = (dictionary["color_r"] as? NSNumber)?.doubleValue
            ?? (dictionary["colorR"] as? NSNumber)?.doubleValue
            ?? 255.0
        self.colorG = (dictionary["color_g"] as? NSNumber)?.doubleValue
            ?? (dictionary["colorG"] as? NSNumber)?.doubleValue
            ?? 255.0
        self.colorB = (dictionary["color_b"] as? NSNumber)?.doubleValue
            ?? (dictionary["colorB"] as? NSNumber)?.doubleValue
            ?? 255.0
        self.color2R = (dictionary["color2_r"] as? NSNumber)?.doubleValue
            ?? (dictionary["color2R"] as? NSNumber)?.doubleValue
            ?? 255.0
        self.color2G = (dictionary["color2_g"] as? NSNumber)?.doubleValue
            ?? (dictionary["color2G"] as? NSNumber)?.doubleValue
            ?? 0.0
        self.color2B = (dictionary["color2_b"] as? NSNumber)?.doubleValue
            ?? (dictionary["color2B"] as? NSNumber)?.doubleValue
            ?? 0.0
    }

    public func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "startTime": startTime,
            "speed": speed,
            "spatialFreq": spatialFreq,
            "bpm": bpm,
            "angle": angle,
            "originU": originU,
            "originV": originV,
            "colorR": colorR,
            "colorG": colorG,
            "colorB": colorB,
            "color2R": color2R,
            "color2G": color2G,
            "color2B": color2B
        ]
    }
}
