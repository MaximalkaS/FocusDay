import Foundation
import SwiftData
import WidgetKit

enum DailyFocusActionResult: Equatable {
    case selectedMainTask(UUID)
    case completedTask(UUID)
    case unchanged
}

@MainActor
enum DailyFocusService {
    @discardableResult
    static func selectRecommendedMainTask(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) throws -> DailyFocusActionResult {
        try DayTransitionService.prepareForCurrentDay(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )

        FocusDayWidgetStorage.clearCompletedMainTaskDisplay()

        let tasks = try fetchTasks(modelContext: modelContext)
        let summaries = try fetchSummaries(modelContext: modelContext)
        let visibleTasks = activeTasks(
            from: tasks,
            summaries: summaries,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let hasExistingDailyState = try hasDailyState(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )
        let dailyState = try todayState(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )

        if let mainTaskId = dailyState.mainTaskId,
           let existingMainTask = visibleTasks.first(where: { $0.id == mainTaskId }),
           existingMainTask.isCompleted == false {
            WidgetSnapshotService.refresh(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            return .selectedMainTask(mainTaskId)
        }

        let recommendedTask = MainTaskRecommendationService.recommendedTask(
            from: visibleTasks,
            energyLevel: hasExistingDailyState ? dailyState.energyLevel : nil
        )

        guard let recommendedTask else {
            dailyState.mainTaskId = nil
            try modelContext.save()
            WidgetSnapshotService.refresh(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            return .unchanged
        }

        dailyState.mainTaskId = recommendedTask.id
        try modelContext.save()
        WidgetSnapshotService.refresh(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )
        return .selectedMainTask(recommendedTask.id)
    }

    @discardableResult
    static func completeTask(
        id taskId: UUID,
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) throws -> DailyFocusActionResult {
        try DayTransitionService.prepareForCurrentDay(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )

        let tasks = try fetchTasks(modelContext: modelContext)
        let summaries = try fetchSummaries(modelContext: modelContext)
        let visibleTasks = activeTasks(
            from: tasks,
            summaries: summaries,
            referenceDate: referenceDate,
            calendar: calendar
        )

        guard let task = visibleTasks.first(where: { $0.id == taskId }) else {
            WidgetSnapshotService.refresh(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            return .unchanged
        }

        guard task.isCompleted == false else {
            WidgetSnapshotService.refresh(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            return .unchanged
        }

        let dailyState = try todayState(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )
        let isMainTask = dailyState.mainTaskId == task.id

        task.isCompleted = true
        task.completedAt = referenceDate

        if isMainTask,
           let displayUntil = calendar.date(
            byAdding: .second,
            value: Int(FocusDayWidgetConstants.completedMainTaskDisplayDuration),
            to: referenceDate
           ) {
            FocusDayWidgetStorage.saveCompletedMainTaskDisplay(taskId: task.id, until: displayUntil)
        }

        try modelContext.save()
        WidgetSnapshotService.refresh(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )
        return .completedTask(task.id)
    }


    @discardableResult
    static func clearExpiredCompletedMainTaskDisplayIfNeeded(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) throws -> Bool {
        guard let pendingDisplay = FocusDayWidgetStorage.completedMainTaskDisplay(),
              pendingDisplay.until <= referenceDate else {
            return false
        }

        let states = try modelContext.fetch(
            FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
        )
        var didChange = false

        if let todayState = states.first(where: { calendar.isDate($0.date, inSameDayAs: referenceDate) }),
           todayState.mainTaskId == pendingDisplay.taskId {
            todayState.mainTaskId = nil
            didChange = true
        }

        FocusDayWidgetStorage.clearCompletedMainTaskDisplay()

        if didChange {
            try modelContext.save()
        }

        return didChange
    }

    static func activeTasks(
        from tasks: [TaskItem],
        summaries: [DailySummary],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> [TaskItem] {
        let todayStart = calendar.startOfDay(for: referenceDate)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)
        let closedDays = Set(
            summaries
                .filter(\.isDayFinished)
                .map { calendar.startOfDay(for: $0.date) }
        )
        let isTodayClosed = closedDays.contains(todayStart)

        return tasks.filter { task in
            let taskDay = calendar.startOfDay(for: task.date)
            if calendar.isDate(taskDay, inSameDayAs: todayStart) {
                return shouldShowTask(task, taskDay: taskDay, closedDays: closedDays)
            }

            guard isTodayClosed,
                  let tomorrowStart,
                  calendar.isDate(taskDay, inSameDayAs: tomorrowStart) else {
                return false
            }

            return shouldShowTask(task, taskDay: taskDay, closedDays: closedDays)
        }
    }

    static func currentStreak(
        tasks: [TaskItem],
        summaries: [DailySummary],
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> Int {
        let today = calendar.startOfDay(for: referenceDate)
        var completedPerDay: [Date: Int] = [:]

        for task in tasks where task.isCompleted {
            let day = calendar.startOfDay(for: task.completedAt ?? task.date)
            guard day <= today else { continue }
            completedPerDay[day, default: 0] += 1
        }

        for summary in summaries {
            let day = calendar.startOfDay(for: summary.date)
            guard day <= today else { continue }
            completedPerDay[day] = max(completedPerDay[day, default: 0], summary.completedTasksCount)
        }

        let productiveDays = Set(completedPerDay.filter { $0.value > 0 }.map(\.key))
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

    private static func fetchTasks(modelContext: ModelContext) throws -> [TaskItem] {
        try modelContext.fetch(
            FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
        )
    }

    private static func fetchSummaries(modelContext: ModelContext) throws -> [DailySummary] {
        try modelContext.fetch(
            FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
        )
    }

    private static func todayState(
        modelContext: ModelContext,
        calendar: Calendar,
        referenceDate: Date
    ) throws -> DailyState {
        let states = try modelContext.fetch(
            FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
        )

        if let existingState = states.first(where: { calendar.isDate($0.date, inSameDayAs: referenceDate) }) {
            return existingState
        }

        let newState = DailyState(date: referenceDate)
        modelContext.insert(newState)
        return newState
    }

    private static func hasDailyState(
        modelContext: ModelContext,
        calendar: Calendar,
        referenceDate: Date
    ) throws -> Bool {
        let states = try modelContext.fetch(
            FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
        )
        return states.contains { calendar.isDate($0.date, inSameDayAs: referenceDate) }
    }

    private static func shouldShowTask(
        _ task: TaskItem,
        taskDay: Date,
        closedDays: Set<Date>
    ) -> Bool {
        task.isCompleted == false || closedDays.contains(taskDay) == false
    }
}
