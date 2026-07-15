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
        repeatSeriesId: UUID? = nil
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
    }

    func nextRepeatDate(after date: Date, calendar: Calendar = .current) -> Date? {
        guard isRepeating, repeatType != .none else { return nil }

        let startDay = calendar.startOfDay(for: date)

        switch repeatType {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: startDay)
        case .weekdays:
            return nextDate(after: startDay, matching: [.monday, .tuesday, .wednesday, .thursday, .friday], calendar: calendar)
        case .weekly:
            let anchorDate = repeatStartDate ?? self.date
            let weekday = RepeatWeekday.from(date: anchorDate, calendar: calendar)
            return nextDate(after: startDay, matching: [weekday], calendar: calendar)
        case .customDays:
            let weekdays = repeatWeekdays
            guard weekdays.isEmpty == false else { return nil }
            return nextDate(after: startDay, matching: weekdays, calendar: calendar)
        }
    }

    private func nextDate(
        after startDay: Date,
        matching weekdays: [RepeatWeekday],
        calendar: Calendar
    ) -> Date? {
        let weekdaySet = Set(weekdays)

        for offset in 1...14 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            let candidateWeekday = RepeatWeekday.from(date: candidate, calendar: calendar)
            if weekdaySet.contains(candidateWeekday) {
                return candidate
            }
        }

        return nil
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
