import SwiftUI

// MARK: - Preset Mode

enum PresetMode: String, Codable, CaseIterable {
    case solid
    case gradient
    case dual

    /// Backward-compatible decoding: old values `gradientTopBottom` and
    /// `dualLeftRight` map to the renamed cases automatically.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "gradientTopBottom": self = .gradient
        case "dualLeftRight":     self = .dual
        default:                  self = PresetMode(rawValue: raw) ?? .solid
        }
    }
}

// MARK: - Split Direction

enum SplitDirection: String, Codable, CaseIterable {
    case horizontal
    case vertical
    case diagonalLeft
    case diagonalRight

    /// The `(startPoint, endPoint)` pair for `LinearGradient` —
    /// a single source of truth shared by fill-light rendering,
    /// preset swatches, and the split-direction picker icons.
    var gradientPoints: (startPoint: UnitPoint, endPoint: UnitPoint) {
        switch self {
        case .horizontal:    return (.leading, .trailing)
        case .vertical:      return (.top, .bottom)
        case .diagonalLeft:  return (.topLeading, .bottomTrailing)
        case .diagonalRight: return (.topTrailing, .bottomLeading)
        }
    }
}

// MARK: - Preset Color

struct PresetColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    static let clear = PresetColor(red: 0, green: 0, blue: 0, alpha: 0)

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var color: Color { Color(uiColor) }

    /// Perceived luminance (ITU-R BT.709) — used for contrast-color decisions.
    var luminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    /// Blends this colour with white by `amount` (0…1).
    ///  `amount = 0` → original colour; `amount = 1` → pure white.
    func lighter(by amount: CGFloat = 0.45) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let blend = 1.0 - amount
        return Color(red: Double(r * blend + amount),
                     green: Double(g * blend + amount),
                     blue: Double(b * blend + amount))
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
}

// MARK: - Light Preset

struct LightPreset: Identifiable, Codable, Equatable {
    let id: Int
    let name: String

    /// Primary fill-light colour.
    let primary: PresetColor
    /// Secondary colour (used when `mode` is `.gradient` or `.dual`).
    let secondary: PresetColor

    let defaultScreenBrightness: Double
    let mode: PresetMode
    let splitDirection: SplitDirection
    let isCustom: Bool

    // MARK: - Convenience accessors (keeps call-sites clean)

    var uiColor: UIColor { primary.uiColor }
    var color: Color { primary.color }

    var secondUIColor: UIColor { secondary.uiColor }
    var secondColor: Color { secondary.color }

    // MARK: - Init (7 params vs the previous 17)

    init(id: Int,
         name: String,
         primary: PresetColor,
         secondary: PresetColor = .clear,
         mode: PresetMode = .solid,
         splitDirection: SplitDirection = .horizontal,
         defaultScreenBrightness: Double = 0.88,
         isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.primary = primary
        self.secondary = secondary
        self.mode = mode
        self.splitDirection = splitDirection
        self.defaultScreenBrightness = defaultScreenBrightness
        self.isCustom = isCustom
    }

    // MARK: - Codable (flat JSON for backward compatibility)

    enum CodingKeys: String, CodingKey {
        case id, name
        case red, green, blue, alpha
        case secondRed, secondGreen, secondBlue, secondAlpha
        case defaultScreenBrightness
        case mode
        case splitDirection
        case isCustom
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        primary = PresetColor(
            red: try c.decode(Double.self, forKey: .red),
            green: try c.decode(Double.self, forKey: .green),
            blue: try c.decode(Double.self, forKey: .blue),
            alpha: try c.decode(Double.self, forKey: .alpha)
        )
        defaultScreenBrightness = try c.decode(Double.self, forKey: .defaultScreenBrightness)
        mode = try c.decode(PresetMode.self, forKey: .mode)
        secondary = PresetColor(
            red: try c.decodeIfPresent(Double.self, forKey: .secondRed) ?? 0,
            green: try c.decodeIfPresent(Double.self, forKey: .secondGreen) ?? 0,
            blue: try c.decodeIfPresent(Double.self, forKey: .secondBlue) ?? 0,
            alpha: try c.decodeIfPresent(Double.self, forKey: .secondAlpha) ?? 0
        )
        splitDirection = try c.decodeIfPresent(SplitDirection.self, forKey: .splitDirection) ?? .horizontal
        isCustom = try c.decode(Bool.self, forKey: .isCustom)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(primary.red, forKey: .red)
        try c.encode(primary.green, forKey: .green)
        try c.encode(primary.blue, forKey: .blue)
        try c.encode(primary.alpha, forKey: .alpha)
        try c.encode(defaultScreenBrightness, forKey: .defaultScreenBrightness)
        try c.encode(mode, forKey: .mode)
        try c.encode(secondary.red, forKey: .secondRed)
        try c.encode(secondary.green, forKey: .secondGreen)
        try c.encode(secondary.blue, forKey: .secondBlue)
        try c.encode(secondary.alpha, forKey: .secondAlpha)
        try c.encode(splitDirection, forKey: .splitDirection)
        try c.encode(isCustom, forKey: .isCustom)
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
