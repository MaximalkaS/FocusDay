import Foundation
import SwiftData

struct DailyProgressPoint: Identifiable, Equatable {
    let date: Date
    let completedCount: Int

    var id: Date { date }
}

struct ProgressCalendarDay: Identifiable, Equatable {
    let dayNumber: Int
    let date: Date?
    let completedCount: Int

    var id: Int { dayNumber }
}

enum WeeklyComparisonTrend: Equatable {
    case increase
    case decrease
    case unchanged
}

struct WeeklyCompletionSummary: Equatable {
    let currentWeekCount: Int
    let previousWeekCount: Int

    var difference: Int {
        abs(currentWeekCount - previousWeekCount)
    }

    var trend: WeeklyComparisonTrend {
        if currentWeekCount > previousWeekCount {
            return .increase
        }

        if currentWeekCount < previousWeekCount {
            return .decrease
        }

        return .unchanged
    }
}

@MainActor
enum DayTransitionService {
    static func prepareForCurrentDay(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) throws {
        let todayStart = calendar.startOfDay(for: referenceDate)
        let taskDescriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
        )
        let tasks = try modelContext.fetch(taskDescriptor)

        try saveHistoricalSummaries(
            for: tasks,
            before: todayStart,
            modelContext: modelContext,
            calendar: calendar
        )

        var didChange = rollForwardUnfinishedTasks(
            tasks,
            to: todayStart,
            calendar: calendar
        )

        didChange = try clearOutdatedMainTaskSelections(
            tasks: tasks,
            todayStart: todayStart,
            modelContext: modelContext,
            calendar: calendar
        ) || didChange

        if didChange || modelContext.hasChanges {
            try modelContext.save()
        }
    }

    private static func saveHistoricalSummaries(
        for tasks: [TaskItem],
        before todayStart: Date,
        modelContext: ModelContext,
        calendar: Calendar
    ) throws {
        let summaries = try modelContext.fetch(
            FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
        )

        let historicalTasks = tasks.filter { calendar.startOfDay(for: $0.date) < todayStart }
        let groupedTasks = Dictionary(grouping: historicalTasks) { task in
            calendar.startOfDay(for: task.date)
        }

        for (day, dayTasks) in groupedTasks {
            let completedCount = dayTasks.filter(\.isCompleted).count
            let totalCount = dayTasks.count

            if let existingSummary = summaries.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
                existingSummary.date = day
                existingSummary.completedTasksCount = max(existingSummary.completedTasksCount, completedCount)
                existingSummary.totalTasksCount = max(existingSummary.totalTasksCount, totalCount)
                if existingSummary.finishedAt == nil {
                    existingSummary.finishedAt = day
                }
            } else {
                modelContext.insert(
                    DailySummary(
                        date: day,
                        completedTasksCount: completedCount,
                        totalTasksCount: totalCount,
                        reflectionText: "",
                        finishedAt: day
                    )
                )
            }
        }
    }

    private static func rollForwardUnfinishedTasks(
        _ tasks: [TaskItem],
        to todayStart: Date,
        calendar: Calendar
    ) -> Bool {
        var didChange = false

        for task in tasks {
            let taskDay = calendar.startOfDay(for: task.date)
            guard taskDay < todayStart, task.isCompleted == false else {
                continue
            }

            task.date = todayStart
            didChange = true
        }

        return didChange
    }

    private static func clearOutdatedMainTaskSelections(
        tasks: [TaskItem],
        todayStart: Date,
        modelContext: ModelContext,
        calendar: Calendar
    ) throws -> Bool {
        let states = try modelContext.fetch(
            FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
        )
        var didChange = false

        for state in states {
            guard let mainTaskId = state.mainTaskId else { continue }
            let stateDay = calendar.startOfDay(for: state.date)
            let selectedTask = tasks.first { $0.id == mainTaskId }
            let selectedTaskDay = selectedTask.map { calendar.startOfDay(for: $0.date) }
            let shouldClearMainTask = stateDay < todayStart
                || selectedTask == nil
                || selectedTask?.isCompleted == true
                || selectedTaskDay != todayStart

            if shouldClearMainTask {
                state.mainTaskId = nil
                didChange = true
            }
        }

        return didChange
    }
}

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var completedTasksCount = 0
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestResult = 0
    @Published private(set) var lastSevenDays: [DailyProgressPoint] = []
    @Published private(set) var lastThirtyDays: [ProgressCalendarDay] = []
    @Published private(set) var productiveDays: Set<Date> = []
    @Published private(set) var referenceDate: Date
    @Published private(set) var showsCurrentStreakWarning = false
    @Published private(set) var weeklySummary = WeeklyCompletionSummary(
        currentWeekCount: 0,
        previousWeekCount: 0
    )
    @Published var statusMessage: String?

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.referenceDate = Date()
    }

    func load(modelContext: ModelContext, referenceDate: Date = Date()) {
        do {
            self.referenceDate = referenceDate
            try DayTransitionService.prepareForCurrentDay(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )

            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
            let tasks = try modelContext.fetch(taskDescriptor)

            let summaryDescriptor = FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
            let summaries = try modelContext.fetch(summaryDescriptor)

            recalculate(
                tasks: tasks,
                summaries: summaries,
                referenceDate: referenceDate
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func recalculate(
        tasks: [TaskItem],
        summaries: [DailySummary] = [],
        referenceDate: Date = Date()
    ) {
        self.referenceDate = referenceDate
        let today = calendar.startOfDay(for: referenceDate)
        let completedPerDay = makeCompletedCountsByDay(
            tasks: tasks,
            summaries: summaries,
            today: today
        )
        let completedToday = tasks.filter {
            guard $0.isCompleted else { return false }
            return calendar.isDate($0.completedAt ?? $0.date, inSameDayAs: referenceDate)
        }.count

        completedTasksCount = completedToday
        productiveDays = Set(completedPerDay.filter { $0.value > 0 }.map(\.key))
        currentStreak = calculateCurrentStreak(
            productiveDays: productiveDays,
            today: today
        )
        showsCurrentStreakWarning = shouldShowCurrentStreakWarning(
            completedToday: completedToday,
            productiveDays: productiveDays,
            today: today
        )
        bestResult = calculateBestResult(from: completedPerDay)
        lastSevenDays = makeLastSevenDays(
            from: completedPerDay,
            referenceDate: referenceDate
        )
        lastThirtyDays = makeLastThirtyDays(
            from: completedPerDay,
            referenceDate: referenceDate
        )
        weeklySummary = makeWeeklySummary(
            from: completedPerDay,
            referenceDate: referenceDate
        )
        statusMessage = nil
    }

    private func makeCompletedCountsByDay(
        tasks: [TaskItem],
        summaries: [DailySummary],
        today: Date
    ) -> [Date: Int] {
        var counts: [Date: Int] = [:]

        for task in tasks where task.isCompleted {
            let day = calendar.startOfDay(for: task.completedAt ?? task.date)
            guard day <= today else { continue }
            counts[day, default: 0] += 1
        }

        for summary in summaries {
            let day = calendar.startOfDay(for: summary.date)
            guard day <= today else { continue }
            counts[day] = max(counts[day, default: 0], summary.completedTasksCount)
        }

        return counts
    }

    private func calculateBestResult(from completedPerDay: [Date: Int]) -> Int {
        completedPerDay.values.max() ?? 0
    }

    private func calculateCurrentStreak(
        productiveDays: Set<Date>,
        today: Date
    ) -> Int {
        var streak = 0
        var checkedDay = productiveDays.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today

        while productiveDays.contains(checkedDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkedDay) else {
                break
            }
            checkedDay = previousDay
        }

        return streak
    }

    private func shouldShowCurrentStreakWarning(
        completedToday: Int,
        productiveDays: Set<Date>,
        today: Date
    ) -> Bool {
        guard completedToday == 0,
              currentStreak > 0,
              let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return false
        }

        return productiveDays.contains(yesterday)
    }

    private func makeLastSevenDays(
        from completedPerDay: [Date: Int],
        referenceDate: Date
    ) -> [DailyProgressPoint] {
        let weekStart = startOfWeek(for: referenceDate)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }

            return DailyProgressPoint(
                date: date,
                completedCount: completedPerDay[date, default: 0]
            )
        }
    }

    private func makeLastThirtyDays(
        from completedPerDay: [Date: Int],
        referenceDate: Date
    ) -> [ProgressCalendarDay] {
        let monthComponents = calendar.dateComponents([.year, .month], from: referenceDate)
        let monthStart = calendar.date(from: monthComponents) ?? calendar.startOfDay(for: referenceDate)
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart)
        let maximumDay = monthRange?.count ?? 30

        return (1...maximumDay).map { dayNumber in
            let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart)

            return ProgressCalendarDay(
                dayNumber: dayNumber,
                date: date,
                completedCount: date.map { completedPerDay[$0, default: 0] } ?? 0
            )
        }
    }

    private func makeWeeklySummary(
        from completedPerDay: [Date: Int],
        referenceDate: Date
    ) -> WeeklyCompletionSummary {
        let currentWeekStart = startOfWeek(for: referenceDate)
        guard let currentWeekEnd = calendar.date(byAdding: .day, value: 7, to: currentWeekStart),
              let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) else {
            return WeeklyCompletionSummary(currentWeekCount: 0, previousWeekCount: 0)
        }

        let today = calendar.startOfDay(for: referenceDate)
        let previousWeekEnd = currentWeekStart
        var currentWeekCount = 0
        var previousWeekCount = 0

        for (day, count) in completedPerDay {
            if day >= currentWeekStart, day <= today, day < currentWeekEnd {
                currentWeekCount += count
            } else if day >= previousWeekStart, day < previousWeekEnd {
                previousWeekCount += count
            }
        }

        return WeeklyCompletionSummary(
            currentWeekCount: currentWeekCount,
            previousWeekCount: previousWeekCount
        )
    }

    private func startOfWeek(for date: Date) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dayStart)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: dayStart) ?? dayStart
    }
}
