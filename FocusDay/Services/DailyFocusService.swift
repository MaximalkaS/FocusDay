import Foundation
import SwiftData
import WidgetKit

enum DailyFocusActionResult: Equatable {
    case selectedMainTask(UUID)
    case completedTask(UUID)
    case unchanged
}

struct RecurringTaskProcessingResult: Equatable {
    let createdCount: Int
    let removedDuplicateCount: Int
    let updatedCount: Int

    var didChange: Bool {
        createdCount > 0 || removedDuplicateCount > 0 || updatedCount > 0
    }
}

@MainActor
enum RecurringTaskService {
    @discardableResult
    static func process(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) throws -> RecurringTaskProcessingResult {
        let today = calendar.startOfDay(for: referenceDate)
        let tasks = try modelContext.fetch(
            FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .forward)]
            )
        )
        let states = try modelContext.fetch(
            FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
        )
        var storedSeries = try modelContext.fetch(FetchDescriptor<RecurringTaskSeries>())

        var updatedCount = normalizeRecurringMetadata(
            tasks: tasks,
            calendar: calendar
        )
        var removedDuplicateCount = 0
        var createdCount = 0
        let recurringTasks = tasks.filter { $0.isRepeating && $0.repeatType != .none }
        let groupedTasks = Dictionary(grouping: recurringTasks, by: \.effectiveRepeatSeriesId)
        var seriesById = Dictionary(uniqueKeysWithValues: storedSeries.map { ($0.id, $0) })

        for marker in tasks where marker.isRepeating == false && marker.repeatSeriesId != nil {
            guard let seriesId = marker.repeatSeriesId else { continue }

            if let series = seriesById[seriesId] {
                if series.isEnabled {
                    series.isEnabled = false
                    updatedCount += 1
                }
            } else if let source = latestTask(in: groupedTasks[seriesId] ?? [], calendar: calendar) {
                let series = makeSeries(
                    from: source,
                    seriesId: seriesId,
                    isEnabled: false,
                    calendar: calendar
                )
                modelContext.insert(series)
                storedSeries.append(series)
                seriesById[seriesId] = series
                updatedCount += 1
            }

            marker.clearRecurrenceMetadata()
            updatedCount += 1
        }

        for (seriesId, seriesTasks) in groupedTasks {
            let series: RecurringTaskSeries
            if let existingSeries = seriesById[seriesId] {
                series = existingSeries
            } else if let source = latestTask(in: seriesTasks, calendar: calendar) {
                series = makeSeries(
                    from: source,
                    seriesId: seriesId,
                    isEnabled: true,
                    calendar: calendar
                )
                modelContext.insert(series)
                storedSeries.append(series)
                seriesById[seriesId] = series
                updatedCount += 1
            } else {
                continue
            }

            if let latestOccurrence = seriesTasks
                .map({ occurrenceDay(for: $0, calendar: calendar) })
                .max(),
               latestOccurrence > calendar.startOfDay(for: series.lastGeneratedDate) {
                series.lastGeneratedDate = latestOccurrence
                updatedCount += 1
            }
        }

        for series in storedSeries where series.isEnabled && series.repeatType != .none {
            let seriesTasks = groupedTasks[series.id] ?? []
            var activeTasks = seriesTasks.filter { $0.isCompleted == false }

            if activeTasks.count > 1 {
                let keeper = preferredActiveTask(from: activeTasks, states: states, calendar: calendar)

                for duplicate in activeTasks where duplicate.id != keeper.id {
                    for state in states where state.mainTaskId == duplicate.id {
                        state.mainTaskId = keeper.id
                    }
                    modelContext.delete(duplicate)
                    removedDuplicateCount += 1
                }

                activeTasks = [keeper]
            }

            if let activeTask = activeTasks.first {
                let activeDay = calendar.startOfDay(for: activeTask.date)
                if activeDay < today {
                    activeTask.date = today
                    activeTask.scheduledDate = today
                    updatedCount += 1
                }
                if calendar.startOfDay(for: series.lastGeneratedDate) < today {
                    series.lastGeneratedDate = today
                    updatedCount += 1
                }
                continue
            }

            guard series.isScheduled(on: today, calendar: calendar),
                  calendar.startOfDay(for: series.lastGeneratedDate) < today else {
                continue
            }

            let alreadyCreatedToday = seriesTasks.contains {
                calendar.isDate($0.scheduledDate ?? $0.date, inSameDayAs: today)
            }
            guard alreadyCreatedToday == false else { continue }

            let nextTask = TaskItem(
                title: series.title,
                taskDescription: series.taskDescription,
                date: today,
                priority: series.priority,
                isCompleted: false,
                completedAt: nil,
                estimatedMinutes: series.estimatedMinutes,
                category: series.category,
                isRepeating: true,
                repeatType: series.repeatType,
                repeatWeekdays: series.repeatWeekdays,
                repeatStartDate: series.startDate,
                repeatSeriesId: series.id,
                scheduledDate: today,
                repeatAnchorWeekday: series.anchorWeekday
            )
            modelContext.insert(nextTask)
            series.lastGeneratedDate = today
            createdCount += 1
        }

        let result = RecurringTaskProcessingResult(
            createdCount: createdCount,
            removedDuplicateCount: removedDuplicateCount,
            updatedCount: updatedCount
        )

        if result.didChange || modelContext.hasChanges {
            try modelContext.save()
        }

        return result
    }

    static func updateSeries(
        from task: TaskItem,
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) throws {
        guard task.isRepeating, task.repeatType != .none else { return }

        let seriesId = task.effectiveRepeatSeriesId
        task.repeatSeriesId = seriesId
        let series = try findSeries(id: seriesId, modelContext: modelContext)
            ?? makeSeries(
                from: task,
                seriesId: seriesId,
                isEnabled: true,
                calendar: calendar
            )

        if series.modelContext == nil {
            modelContext.insert(series)
        }

        apply(task: task, to: series, calendar: calendar)
        series.isEnabled = true
        let occurrence = occurrenceDay(for: task, calendar: calendar)
        if occurrence > calendar.startOfDay(for: series.lastGeneratedDate) {
            series.lastGeneratedDate = occurrence
        }
    }

    static func disableSeries(
        for task: TaskItem,
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) throws {
        guard task.isRepeating, task.repeatType != .none else { return }
        let seriesId = task.repeatSeriesId ?? task.id
        task.repeatSeriesId = seriesId

        let series = try findSeries(id: seriesId, modelContext: modelContext)
            ?? makeSeries(
                from: task,
                seriesId: seriesId,
                isEnabled: false,
                calendar: calendar
            )

        if series.modelContext == nil {
            modelContext.insert(series)
        }
        series.isEnabled = false
    }

    static func recordDeletedOccurrence(
        for task: TaskItem,
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) throws {
        guard task.isRepeating, task.repeatType != .none else { return }

        try updateSeries(from: task, modelContext: modelContext, calendar: calendar)
        guard let seriesId = task.repeatSeriesId,
              let series = try findSeries(id: seriesId, modelContext: modelContext) else {
            return
        }

        let occurrence = occurrenceDay(for: task, calendar: calendar)
        if occurrence > calendar.startOfDay(for: series.lastGeneratedDate) {
            series.lastGeneratedDate = occurrence
        }
    }

    private static func normalizeRecurringMetadata(
        tasks: [TaskItem],
        calendar: Calendar
    ) -> Int {
        var updatedCount = 0

        for task in tasks where task.isRepeating && task.repeatType != .none {
            if task.repeatSeriesId == nil {
                task.repeatSeriesId = task.id
                updatedCount += 1
            }

            if task.repeatStartDate == nil {
                task.repeatStartDate = calendar.startOfDay(for: task.date)
                updatedCount += 1
            }

            if task.scheduledDate == nil {
                task.scheduledDate = calendar.startOfDay(for: task.date)
                updatedCount += 1
            }

            if task.repeatType == .weekly, task.repeatAnchorWeekday == nil {
                task.repeatAnchorWeekday = RepeatWeekday.from(
                    date: task.repeatStartDate ?? task.date,
                    calendar: calendar
                )
                updatedCount += 1
            }
        }

        return updatedCount
    }

    private static func findSeries(
        id: UUID,
        modelContext: ModelContext
    ) throws -> RecurringTaskSeries? {
        try modelContext.fetch(FetchDescriptor<RecurringTaskSeries>())
            .first { $0.id == id }
    }

    private static func makeSeries(
        from task: TaskItem,
        seriesId: UUID,
        isEnabled: Bool,
        calendar: Calendar
    ) -> RecurringTaskSeries {
        let occurrence = occurrenceDay(for: task, calendar: calendar)
        return RecurringTaskSeries(
            id: seriesId,
            title: task.title,
            taskDescription: task.taskDescription,
            priority: task.priority,
            estimatedMinutes: task.estimatedMinutes,
            category: task.category,
            repeatType: task.repeatType,
            repeatWeekdays: task.repeatWeekdays,
            startDate: calendar.startOfDay(for: task.repeatStartDate ?? task.date),
            anchorWeekday: task.repeatAnchorWeekday,
            lastGeneratedDate: occurrence,
            isEnabled: isEnabled
        )
    }

    private static func apply(
        task: TaskItem,
        to series: RecurringTaskSeries,
        calendar: Calendar
    ) {
        series.title = task.title
        series.taskDescription = task.taskDescription
        series.priority = task.priority
        series.estimatedMinutes = task.estimatedMinutes
        series.category = task.category
        series.repeatType = task.repeatType
        series.repeatWeekdays = task.repeatWeekdays
        series.startDate = calendar.startOfDay(for: task.repeatStartDate ?? task.date)
        series.anchorWeekday = task.repeatAnchorWeekday
    }

    private static func preferredActiveTask(
        from tasks: [TaskItem],
        states: [DailyState],
        calendar: Calendar
    ) -> TaskItem {
        let selectedTaskIds = Set(states.compactMap(\.mainTaskId))
        if let selectedTask = tasks.first(where: { selectedTaskIds.contains($0.id) }) {
            return selectedTask
        }

        return tasks.min { first, second in
            let firstDay = occurrenceDay(for: first, calendar: calendar)
            let secondDay = occurrenceDay(for: second, calendar: calendar)
            if firstDay != secondDay {
                return firstDay < secondDay
            }
            return first.id.uuidString < second.id.uuidString
        } ?? tasks[0]
    }

    private static func latestTask(
        in tasks: [TaskItem],
        calendar: Calendar
    ) -> TaskItem? {
        tasks.max { first, second in
            let firstDay = occurrenceDay(for: first, calendar: calendar)
            let secondDay = occurrenceDay(for: second, calendar: calendar)
            if firstDay != secondDay {
                return firstDay < secondDay
            }
            return (first.completedAt ?? first.date) < (second.completedAt ?? second.date)
        }
    }

    private static func occurrenceDay(
        for task: TaskItem,
        calendar: Calendar
    ) -> Date {
        calendar.startOfDay(for: task.scheduledDate ?? task.date)
    }
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
        try RecurringTaskService.process(
            modelContext: modelContext,
            calendar: calendar,
            referenceDate: referenceDate
        )
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
