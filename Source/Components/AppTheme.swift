import SwiftUI

// MARK: - Colors

extension Color {
    static let appBackground = Color(hex: "#1a1a1a")
    static let appSurface = Color.white.opacity(0.08)
    static let appSurfaceActive = Color.white.opacity(0.15)
    static let appBorder = Color.white.opacity(0.12)
    static let appSuccess = Color(hex: "#00B894")
    static let appWarning = Color(hex: "#FDCB6E")
    static let appError = Color(hex: "#FF4444")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Animation

struct AppAnimation {
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.7
    static let easeInOut = Animation.easeInOut(duration: 0.25)
    static let spring = Animation.spring(response: springResponse, dampingFraction: springDamping)
    static let quick = Animation.easeOut(duration: 0.15)
}

