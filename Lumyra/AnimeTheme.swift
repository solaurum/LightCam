import SwiftUI

/// App-wide anime / magical-girl colour palette.
/// Extracted from `ContentView` so every view can reuse the same constants
/// without duplicating colour literals.
enum AnimeTheme {
    // Background
    static let bgTop = Color(red: 0.06, green: 0.04, blue: 0.14)
    static let bgMid = Color(red: 0.08, green: 0.05, blue: 0.16)
    static let bgBottom = Color(red: 0.04, green: 0.02, blue: 0.10)

    // Accent
    static let sakura = Color(red: 0.949, green: 0.627, blue: 0.710)
    static let starlight = Color(red: 1.0, green: 0.835, blue: 0.55)
    static let magicalPurple = Color(red: 0.706, green: 0.573, blue: 0.878)
    static let nightGlow = Color(red: 0.353, green: 0.620, blue: 0.714)

    /// The 8 built-in preset primary colours, for use in anime-style gradient backgrounds.
    static let presetPalette: [Color] = [
        Color(red: 1.000, green: 0.722, blue: 0.816),  // Sakura Breeze
        Color(red: 1.000, green: 0.851, blue: 0.400),  // Golden Hour
        Color(red: 0.690, green: 0.533, blue: 0.976),  // Aurora Purple
        Color(red: 1.000, green: 0.671, blue: 0.557),  // Coral Reef
        Color(red: 0.659, green: 0.902, blue: 0.941),  // Glacier Blue
        Color(red: 0.784, green: 0.910, blue: 0.424),  // Matcha Mist
        Color(red: 0.910, green: 0.902, blue: 0.890),  // Smoky Silver
        Color(red: 0.102, green: 0.420, blue: 0.486),  // Deep Sea Glow
    ]

    /// Secondary (bottom) colours from the 8 built-in presets — deeper, richer tones
    /// that complement the primary palette for layered gradient effects.
    static let secondaryPalette: [Color] = [
        Color(red: 1.000, green: 0.541, blue: 0.710),  // Sakura deep pink
        Color(red: 0.961, green: 0.651, blue: 0.137),  // Golden warm orange
        Color(red: 0.608, green: 0.427, blue: 0.843),  // Aurora deep purple
        Color(red: 0.973, green: 0.486, blue: 0.416),  // Coral red
        Color(red: 0.482, green: 0.831, blue: 0.918),  // Glacier sky blue
        Color(red: 0.659, green: 0.847, blue: 0.306),  // Matcha emerald
        Color(red: 0.835, green: 0.827, blue: 0.816),  // Smoky cool grey
        Color(red: 0.051, green: 0.310, blue: 0.361),  // Deep Sea dark teal
    ]

    /// All 16 preset colours interleaved — primary then secondary for each preset.
    /// Computed from `presetPalette` + `secondaryPalette` so colours are defined once.
    static var fullPalette: [Color] {
        zip(presetPalette, secondaryPalette).flatMap { [$0, $1] }
    }
}
