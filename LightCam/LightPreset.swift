import SwiftUI

enum PresetMode: String, Codable, CaseIterable {
    case solid
    case gradientTopBottom
    case dualLeftRight
}

struct LightPreset: Identifiable, Codable {
    let id: Int
    let name: String
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    let temp: Int
    let defaultScreenBrightness: Double
    let defaultColorBrightness: Double
    let mode: PresetMode
    let secondRed: Double
    let secondGreen: Double
    let secondBlue: Double
    let secondAlpha: Double
    let isCustom: Bool

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var color: Color { Color(uiColor) }

    var secondUIColor: UIColor {
        UIColor(red: secondRed, green: secondGreen, blue: secondBlue, alpha: secondAlpha)
    }

    var secondColor: Color { Color(secondUIColor) }

    init(id: Int, name: String, red: Double, green: Double, blue: Double, alpha: Double = 1.0,
         temp: Int, defaultScreenBrightness: Double = 0.88, defaultColorBrightness: Double = 0.0,
         mode: PresetMode = .solid,
         secondRed: Double = 0, secondGreen: Double = 0, secondBlue: Double = 0, secondAlpha: Double = 0,
         isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.temp = temp
        self.defaultScreenBrightness = defaultScreenBrightness
        self.defaultColorBrightness = defaultColorBrightness
        self.mode = mode
        self.secondRed = secondRed
        self.secondGreen = secondGreen
        self.secondBlue = secondBlue
        self.secondAlpha = secondAlpha
        self.isCustom = isCustom
    }

    /// Convenience init for custom presets built from UIColor values.
    init(id: Int, name: String, mode: PresetMode, first: UIColor, second: UIColor?,
         defaultScreenBrightness: Double = 0.88, isCustom: Bool = true) {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        first.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        second?.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        self.id = id
        self.name = name
        self.red = Double(r1)
        self.green = Double(g1)
        self.blue = Double(b1)
        self.alpha = Double(a1)
        self.temp = 5500
        self.defaultScreenBrightness = defaultScreenBrightness
        self.defaultColorBrightness = 0.0
        self.mode = mode
        self.secondRed = Double(r2)
        self.secondGreen = Double(g2)
        self.secondBlue = Double(b2)
        self.secondAlpha = Double(a2)
        self.isCustom = isCustom
    }
}

// MARK: - Persistence

extension UserDefaults {
    private static let customPresetsKey = "com.lightcam.customPresets"
    private static let nextCustomIdKey = "com.lightcam.nextCustomPresetId"

    func loadCustomPresets() -> [LightPreset] {
        guard let data = data(forKey: Self.customPresetsKey) else { return [] }
        return (try? JSONDecoder().decode([LightPreset].self, from: data)) ?? []
    }

    func saveCustomPresets(_ presets: [LightPreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        set(data, forKey: Self.customPresetsKey)
    }

    func allocateCustomPresetId() -> Int {
        let current = integer(forKey: Self.nextCustomIdKey)
        let next = current < 1000 ? 1000 : current + 1
        set(next, forKey: Self.nextCustomIdKey)
        return next
    }
}
