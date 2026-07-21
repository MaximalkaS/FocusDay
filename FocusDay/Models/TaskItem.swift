import Foundation
import SwiftData

@Model
final class TaskItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var date: Date
    var priorityRawValue: String
    var isCompleted: Bool
    var completedAt: Date?
    var estimatedMinutes: Int
    var categoryRawValue: String
    var isRepeating: Bool = false
    var repeatTypeRawValue: String = TaskRepeatType.none.rawValue
    var repeatWeekdaysRawValue: String = ""
    var repeatStartDate: Date?
    var repeatSeriesId: UUID?
    var scheduledDate: Date?
    var repeatAnchorWeekdayRawValue: Int?

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .personal }
        set { categoryRawValue = newValue.rawValue }
    }

    var repeatType: TaskRepeatType {
        get { isRepeating ? (TaskRepeatType(rawValue: repeatTypeRawValue) ?? .none) : .none }
        set { repeatTypeRawValue = newValue.rawValue }
    }

    var repeatWeekdays: [RepeatWeekday] {
        get {
            repeatWeekdaysRawValue
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                .compactMap(RepeatWeekday.init(rawValue:))
                .uniqued()
                .sorted()
        }
        set {
            repeatWeekdaysRawValue = Array(Set(newValue))
                .sorted()
                .map { String($0.rawValue) }
                .joined(separator: ",")
        }
    }

    var effectiveRepeatSeriesId: UUID {
        repeatSeriesId ?? id
    }

    var repeatAnchorWeekday: RepeatWeekday? {
        get { repeatAnchorWeekdayRawValue.flatMap(RepeatWeekday.init(rawValue:)) }
        set { repeatAnchorWeekdayRawValue = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        date: Date = Date(),
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        estimatedMinutes: Int = 30,
        category: TaskCategory = .personal,
        isRepeating: Bool = false,
        repeatType: TaskRepeatType = .none,
        repeatWeekdays: [RepeatWeekday] = [],
        repeatStartDate: Date? = nil,
        repeatSeriesId: UUID? = nil,
        scheduledDate: Date? = nil,
        repeatAnchorWeekday: RepeatWeekday? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.date = date
        self.priorityRawValue = priority.rawValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.estimatedMinutes = estimatedMinutes
        self.categoryRawValue = category.rawValue
        self.isRepeating = isRepeating && repeatType != .none
        self.repeatTypeRawValue = self.isRepeating ? repeatType.rawValue : TaskRepeatType.none.rawValue
        self.repeatWeekdaysRawValue = Array(Set(repeatWeekdays))
            .sorted()
            .map { String($0.rawValue) }
            .joined(separator: ",")
        self.repeatStartDate = repeatStartDate
        self.repeatSeriesId = repeatSeriesId
        self.scheduledDate = scheduledDate
        self.repeatAnchorWeekdayRawValue = repeatAnchorWeekday?.rawValue
    }

    func clearRecurrenceMetadata() {
        isRepeating = false
        repeatTypeRawValue = TaskRepeatType.none.rawValue
        repeatWeekdaysRawValue = ""
        repeatStartDate = nil
        repeatSeriesId = nil
        scheduledDate = nil
        repeatAnchorWeekdayRawValue = nil
    }

}

@Model
final class RecurringTaskSeries {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var priorityRawValue: String
    var estimatedMinutes: Int
    var categoryRawValue: String
    var repeatTypeRawValue: String
    var repeatWeekdaysRawValue: String
    var startDate: Date
    var anchorWeekdayRawValue: Int?
    var lastGeneratedDate: Date
    var isEnabled: Bool = true

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .personal }
        set { categoryRawValue = newValue.rawValue }
    }

    var repeatType: TaskRepeatType {
        get { TaskRepeatType(rawValue: repeatTypeRawValue) ?? .none }
        set { repeatTypeRawValue = newValue.rawValue }
    }

    var repeatWeekdays: [RepeatWeekday] {
        get {
            repeatWeekdaysRawValue
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                .compactMap(RepeatWeekday.init(rawValue:))
                .uniqued()
                .sorted()
        }
        set {
            repeatWeekdaysRawValue = Array(Set(newValue))
                .sorted()
                .map { String($0.rawValue) }
                .joined(separator: ",")
        }
    }

    var anchorWeekday: RepeatWeekday? {
        get { anchorWeekdayRawValue.flatMap(RepeatWeekday.init(rawValue:)) }
        set { anchorWeekdayRawValue = newValue?.rawValue }
    }

    init(
        id: UUID,
        title: String,
        taskDescription: String,
        priority: TaskPriority,
        estimatedMinutes: Int,
        category: TaskCategory,
        repeatType: TaskRepeatType,
        repeatWeekdays: [RepeatWeekday],
        startDate: Date,
        anchorWeekday: RepeatWeekday?,
        lastGeneratedDate: Date,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.priorityRawValue = priority.rawValue
        self.estimatedMinutes = estimatedMinutes
        self.categoryRawValue = category.rawValue
        self.repeatTypeRawValue = repeatType.rawValue
        self.repeatWeekdaysRawValue = Array(Set(repeatWeekdays))
            .sorted()
            .map { String($0.rawValue) }
            .joined(separator: ",")
        self.startDate = startDate
        self.anchorWeekdayRawValue = anchorWeekday?.rawValue
        self.lastGeneratedDate = lastGeneratedDate
        self.isEnabled = isEnabled
    }

    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        guard isEnabled, repeatType != .none,
              day >= calendar.startOfDay(for: startDate) else {
            return false
        }

        switch repeatType {
        case .none:
            return false
        case .daily:
            return true
        case .weekdays:
            return Set([RepeatWeekday.monday, .tuesday, .wednesday, .thursday, .friday])
                .contains(RepeatWeekday.from(date: day, calendar: calendar))
        case .weekly:
            return RepeatWeekday.from(date: day, calendar: calendar)
                == (anchorWeekday ?? RepeatWeekday.from(date: startDate, calendar: calendar))
        case .customDays:
            return Set(repeatWeekdays).contains(RepeatWeekday.from(date: day, calendar: calendar))
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
