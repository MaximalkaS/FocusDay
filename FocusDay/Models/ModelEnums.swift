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


enum TaskRepeatType: String, CaseIterable, Codable, Identifiable {
    case none
    case daily
    case weekdays
    case weekly
    case customDays

    var id: String { rawValue }

    static var selectableCases: [TaskRepeatType] {
        [.daily, .weekdays, .weekly, .customDays]
    }

    var title: String {
        switch self {
        case .none:
            LocalizedStrings.repeatNone
        case .daily:
            LocalizedStrings.repeatEveryDay
        case .weekdays:
            LocalizedStrings.repeatWeekdays
        case .weekly:
            LocalizedStrings.repeatWeekly
        case .customDays:
            LocalizedStrings.repeatCustomDays
        }
    }
}

enum RepeatWeekday: Int, CaseIterable, Codable, Identifiable, Comparable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var id: Int { rawValue }

    var sortOrder: Int {
        switch self {
        case .monday:
            0
        case .tuesday:
            1
        case .wednesday:
            2
        case .thursday:
            3
        case .friday:
            4
        case .saturday:
            5
        case .sunday:
            6
        }
    }

    var title: String {
        let titles = LocalizedStrings.weekdayShortTitles
        guard titles.indices.contains(sortOrder) else { return "" }
        return titles[sortOrder]
    }

    static func < (lhs: RepeatWeekday, rhs: RepeatWeekday) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    static func from(date: Date, calendar: Calendar = .current) -> RepeatWeekday {
        RepeatWeekday(rawValue: calendar.component(.weekday, from: date)) ?? .monday
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
