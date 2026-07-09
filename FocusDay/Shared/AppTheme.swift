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

enum AppTypography {
    static let screenTitle = Font.system(size: 30, weight: .bold)
    static let screenSubtitle = Font.subheadline.weight(.medium)
    static let eveningScreenSubtitle = Font.system(size: 17, weight: .medium)

    static let cardTitleLarge = Font.system(size: 23, weight: .semibold)
    static let cardQuestion = Font.system(size: 22, weight: .semibold)
    static let calendarTitle = Font.system(size: 21, weight: .bold)
    static let sectionTitle = Font.headline
    static let sectionTitleSemibold = Font.headline.weight(.semibold)
    static let sectionTitleBold = Font.headline.weight(.bold)
    static let secondarySectionTitle = Font.system(size: 18, weight: .semibold)

    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let controlText = Font.system(size: 16, weight: .medium)
    static let taskTitle = Font.subheadline.weight(.semibold)
    static let taskMetadata = Font.caption.weight(.medium)
    static let compact = Font.caption
    static let compactMedium = Font.caption.weight(.medium)
    static let compactSemibold = Font.caption.weight(.semibold)
    static let tiny = Font.caption2
    static let tinySemibold = Font.caption2.weight(.semibold)
    static let tinyBold = Font.caption2.weight(.bold)
    static let validation = Font.footnote.weight(.semibold)

    static let buttonText = Font.subheadline.weight(.semibold)
    static let choiceButtonText = Font.subheadline.weight(.medium)
    static let primaryButton = Font.subheadline.weight(.semibold)
    static let finishDayButton = Font.system(size: 17, weight: .semibold)
    static let taskMenuItem = Font.system(size: 16, weight: .semibold)
    static let tabLabel = Font.caption.weight(.semibold)

    static let progressMetricValue = Font.system(size: 25, weight: .bold)
    static let progressMetricUnit = Font.system(size: 15, weight: .bold)
    static let progressMetricTitle = Font.system(size: 11, weight: .bold)
    static let progressRingValue = Font.title2.bold()
    static let progressCardValue = Font.title3.bold()
    static let streakCount = Font.system(size: 30, weight: .bold)
    static let eveningCompletedCount = Font.system(size: 24, weight: .bold)

    static let titleIcon = Font.title2.weight(.semibold)
    static let plusIcon = Font.system(size: 24, weight: .semibold)
    static let goalIcon = Font.system(size: 24, weight: .semibold)
    static let notificationIcon = Font.system(size: 30, weight: .semibold)
    static let streakIcon = Font.system(size: 24, weight: .bold)
    static let eveningChoiceIcon = Font.system(size: 17, weight: .semibold)
    static let snackbarSuccessIcon = Font.title2
    static let emptyStateIcon = Font.system(size: 34)
    static let storageWarningIcon = Font.system(size: 38, weight: .semibold)

    static func checkboxIcon(size: CGFloat) -> Font {
        Font.system(size: size * 0.48, weight: .bold)
    }

    static func calendarDay(cellSize: CGFloat) -> Font {
        Font.system(size: max(11, cellSize * 0.34), weight: .bold)
    }
}

enum AppMotion {
    static func quick(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.2)
    }

    static func smooth(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.14) : .easeInOut(duration: 0.28)
    }

    static func gentleSpring(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.14) : .spring(response: 0.24, dampingFraction: 0.78)
    }

    static func appearTransition(_ reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96))
    }

    static func checkboxTransition(_ reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.7))
    }
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
