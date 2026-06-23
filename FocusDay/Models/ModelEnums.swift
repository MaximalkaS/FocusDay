import Foundation

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            LocalizedStrings.lowPriority
        case .medium:
            LocalizedStrings.mediumPriority
        case .high:
            LocalizedStrings.highPriority
        }
    }

    var rank: Int {
        switch self {
        case .low:
            1
        case .medium:
            2
        case .high:
            3
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case study
    case sport
    case work
    case habits
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study:
            LocalizedStrings.goalStudy
        case .sport:
            LocalizedStrings.goalSport
        case .work:
            LocalizedStrings.goalWork
        case .habits:
            LocalizedStrings.goalHabits
        case .personal:
            LocalizedStrings.goalPersonal
        }
    }
}

enum EnergyLevel: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            LocalizedStrings.lowEnergy
        case .medium:
            LocalizedStrings.mediumEnergy
        case .high:
            LocalizedStrings.highEnergy
        }
    }
}

enum Mood: String, CaseIterable, Codable, Identifiable {
    case calm
    case tired
    case motivated
    case anxious

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm:
            LocalizedStrings.calmMood
        case .tired:
            LocalizedStrings.tiredMood
        case .motivated:
            LocalizedStrings.motivatedMood
        case .anxious:
            LocalizedStrings.anxiousMood
        }
    }

    var symbolName: String {
        switch self {
        case .calm:
            "leaf"
        case .tired:
            "moon"
        case .motivated:
            "sparkles"
        case .anxious:
            "wind"
        }
    }
}

enum FocusGoal: String, CaseIterable, Codable, Identifiable {
    case study
    case sport
    case work
    case habits
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study:
            LocalizedStrings.goalStudy
        case .sport:
            LocalizedStrings.goalSport
        case .work:
            LocalizedStrings.goalWork
        case .habits:
            LocalizedStrings.goalHabits
        case .personal:
            LocalizedStrings.goalPersonal
        }
    }
}
