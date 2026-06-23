import SwiftUI

enum AppTheme {
    static let background = Color(hex: "E3F2FD")
    static let screenBackground = Color(hex: "F6F9FE")
    static let primaryBlue = Color(hex: "007BFF")
    static let text = Color(hex: "333333")
    static let mutedText = Color(hex: "667085")
    static let placeholderText = Color(hex: "6B7280")
    static let fieldBackground = Color.white
    static let card = Color.white.opacity(0.92)
    static let success = Color(hex: "2E7D32")
    static let warning = Color(hex: "F9A825")
    static let softBlue = Color(hex: "BBDEFB")
    static let purple = Color(hex: "7C3AED")
    static let orange = Color(hex: "F97316")
    static let danger = Color(hex: "EF4444")
    static let lowPriority = Color(hex: "34C759")
    static let mediumPriority = Color(hex: "FF9F0A")
    static let highPriority = Color(hex: "FF5A5F")
    static let flexiblePriority = Color(hex: "5E5CE6")
}

extension Color {
    init(hex: String) {
        let normalizedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: normalizedHex).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch normalizedHex.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
            alpha = 255
        case 6:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 255
        case 8:
            red = value >> 24
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            red = 51
            green = 51
            blue = 51
            alpha = 255
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
