import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetSnapshotService {
    static func refresh(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) {
        do {
            _ = try makeAndSaveSnapshot(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            let fallbackSnapshot = FocusDayWidgetSnapshot(
                updatedAt: Date(),
                mainTask: nil,
                additionalTasks: [],
                completedTodayCount: 0,
                totalTodayCount: 0,
                availableTaskCount: 0,
                currentStreak: 0,
                isPremium: FocusDayWidgetStorage.isPremiumPlan(),
                completedMainTaskDisplayUntil: nil
            )
            FocusDayWidgetStorage.saveSnapshot(fallbackSnapshot)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    static func makeAndSaveSnapshot(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) throws -> FocusDayWidgetSnapshot {
        let tasks = try modelContext.fetch(
            FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
        )
        let summaries = try modelContext.fetch(
            FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
        )
        let states = try modelContext.fetch(
            FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
        )
        let snapshot = makeSnapshot(
            tasks: tasks,
            summaries: summaries,
            states: states,
            calendar: calendar,
            referenceDate: referenceDate
        )
        FocusDayWidgetStorage.saveSnapshot(snapshot)
        return snapshot
    }

    static func makeTimelineSnapshot(
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> FocusDayWidgetSnapshot {
        do {
            let container = try FocusDayModelContainerFactory.makeModelContainer()
            let modelContext = ModelContext(container)
            try DailyFocusService.clearExpiredCompletedMainTaskDisplayIfNeeded(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            return try makeAndSaveSnapshot(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
        } catch {
            return FocusDayWidgetStorage.loadSnapshot()
        }
    }

    private static func makeSnapshot(
        tasks: [TaskItem],
        summaries: [DailySummary],
        states: [DailyState],
        calendar: Calendar,
        referenceDate: Date
    ) -> FocusDayWidgetSnapshot {
        let visibleTasks = DailyFocusService.activeTasks(
            from: tasks,
            summaries: summaries,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let todayState = states.first { calendar.isDate($0.date, inSameDayAs: referenceDate) }
        let selectedMainTaskId = todayState?.mainTaskId
        let selectedMainTask = selectedMainTaskId.flatMap { mainTaskId in
            visibleTasks.first { $0.id == mainTaskId }
        }
        let pendingDisplay = FocusDayWidgetStorage.completedMainTaskDisplay()
        let shouldShowCompletedMainTask = selectedMainTask.map { task in
            task.isCompleted
                && pendingDisplay?.taskId == task.id
                && (pendingDisplay?.until ?? .distantPast) > referenceDate
        } ?? false
        let displayedMainTask: TaskItem? = {
            guard let selectedMainTask else { return nil }
            if selectedMainTask.isCompleted == false || shouldShowCompletedMainTask {
                return selectedMainTask
            }
            return nil
        }()
        let additionalTasks = visibleTasks
            .filter { task in
                guard let selectedMainTaskId else { return true }
                return task.id != selectedMainTaskId
            }
            .sorted(by: widgetTaskSort)
            .prefix(3)
            .map(makeWidgetTask)
        let completedMainTaskDisplayUntil = shouldShowCompletedMainTask ? pendingDisplay?.until : nil

        return FocusDayWidgetSnapshot(
            updatedAt: Date(),
            mainTask: displayedMainTask.map(makeWidgetTask),
            additionalTasks: Array(additionalTasks),
            completedTodayCount: visibleTasks.filter(\.isCompleted).count,
            totalTodayCount: visibleTasks.count,
            availableTaskCount: visibleTasks.filter { $0.isCompleted == false }.count,
            currentStreak: DailyFocusService.currentStreak(
                tasks: tasks,
                summaries: summaries,
                calendar: calendar,
                referenceDate: referenceDate
            ),
            isPremium: FocusDayWidgetStorage.isPremiumPlan(),
            completedMainTaskDisplayUntil: completedMainTaskDisplayUntil
        )
    }

    private static func widgetTaskSort(_ firstTask: TaskItem, _ secondTask: TaskItem) -> Bool {
        if firstTask.isCompleted != secondTask.isCompleted {
            return firstTask.isCompleted == false
        }

        if firstTask.priority.rank != secondTask.priority.rank {
            return firstTask.priority.rank > secondTask.priority.rank
        }

        return firstTask.date < secondTask.date
    }

    private static func makeWidgetTask(_ task: TaskItem) -> FocusDayWidgetTask {
        FocusDayWidgetTask(
            id: task.id,
            title: task.title,
            categoryTitle: task.category.title,
            priorityTitle: task.priority.title,
            priorityRawValue: task.priority.rawValue,
            isCompleted: task.isCompleted
        )
    }
}
