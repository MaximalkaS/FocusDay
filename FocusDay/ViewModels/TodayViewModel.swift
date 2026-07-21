import Foundation
import SwiftData
import SwiftUI

struct StreakCelebration: Equatable {
    let dayCount: Int
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var dailyState: DailyState?
    @Published private(set) var mainTask: TaskItem?
    @Published var selectedMood: Mood = .calm
    @Published var selectedEnergyLevel: EnergyLevel = .medium
    @Published var statusMessage: String?

    private var modelContext: ModelContext?
    private let calendar: Calendar
    private let aiPlanningService: AIPlanningServiceProtocol

    init(
        calendar: Calendar = .current,
        aiPlanningService: AIPlanningServiceProtocol = PlaceholderAIPlanningService()
    ) {
        self.calendar = calendar
        self.aiPlanningService = aiPlanningService
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizedStrings.dateLocale
        formatter.dateFormat = LocalizedStrings.fullDateFormat
        return formatter.string(from: Date())
    }

    var additionalTasks: [TaskItem] {
        guard let mainTask else { return tasks }
        return tasks.filter { $0.id != mainTask.id }
    }

    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var totalTasksCount: Int {
        tasks.count
    }

    var progressValue: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadToday()
    }

    func loadToday() {
        guard let modelContext else { return }

        do {
            let referenceDate = Date()

            try DayTransitionService.prepareForCurrentDay(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
            try DailyFocusService.clearExpiredCompletedMainTaskDisplayIfNeeded(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )

            let summaryDescriptor = FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
            let summaries = try modelContext.fetch(summaryDescriptor)

            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(taskDescriptor)
            tasks = activeTasks(
                from: allTasks,
                summaries: summaries,
                referenceDate: referenceDate
            )

            let stateDescriptor = FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
            let allStates = try modelContext.fetch(stateDescriptor)

            if let existingState = allStates.first(where: { calendar.isDate($0.date, inSameDayAs: referenceDate) }) {
                dailyState = existingState
            } else {
                let newState = DailyState(date: referenceDate)
                modelContext.insert(newState)
                dailyState = newState
                saveContext()
            }

            selectedMood = dailyState?.mood ?? .calm
            selectedEnergyLevel = dailyState?.energyLevel ?? .medium
            refreshMainTaskFromState()
            WidgetSnapshotService.refresh(
                modelContext: modelContext,
                calendar: calendar,
                referenceDate: referenceDate
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func updateMood(_ mood: Mood) {
        selectedMood = mood
        dailyState?.mood = mood
        saveContext()
    }

    func updateEnergyLevel(_ energyLevel: EnergyLevel) {
        selectedEnergyLevel = energyLevel
        dailyState?.energyLevel = energyLevel
        saveContext()
    }

    func chooseMainTask() {
        guard let suggestedTask = suggestedMainTask() else { return }
        setMainTask(suggestedTask)
    }

    func setMainTask(_ task: TaskItem) {
        guard task.isCompleted == false else { return }

        dailyState?.mainTaskId = task.id
        mainTask = task
        saveContext()
    }

    func removeMainTask() {
        clearMainTaskSelection()
        saveContext()
    }

    func deleteTask(_ task: TaskItem) -> Bool {
        guard let modelContext else { return false }

        if dailyState?.mainTaskId == task.id {
            clearMainTaskSelection()
        }

        do {
            try RecurringTaskService.recordDeletedOccurrence(
                for: task,
                modelContext: modelContext,
                calendar: calendar
            )
            modelContext.delete(task)
            try modelContext.save()
            WidgetSnapshotService.refresh(modelContext: modelContext, calendar: calendar)
            loadToday()
            return true
        } catch {
            modelContext.rollback()
            statusMessage = error.localizedDescription
            loadToday()
            return false
        }
    }

    func toggleCompletion(for task: TaskItem) -> StreakCelebration? {
        let shouldCheckStreakCelebration = task.isCompleted == false
        let streakCelebration = shouldCheckStreakCelebration ? makeStreakCelebrationIfNeeded() : nil

        let isNowCompleted = task.isCompleted == false
        task.isCompleted = isNowCompleted
        task.completedAt = isNowCompleted ? Date() : nil

        let didSave = saveContext(processRecurringTasks: isNowCompleted && task.isRepeating)
        loadToday()

        guard didSave, task.isCompleted, let streakCelebration else {
            return nil
        }

        markStreakCelebrationShownToday()
        return streakCelebration
    }

    func toggleMainTaskCompletion() -> StreakCelebration? {
        guard let mainTask else { return nil }
        return toggleCompletion(for: mainTask)
    }

    func createPlanFromText(_ text: String) async {
        do {
            _ = try await aiPlanningService.makePlan(
                from: text,
                currentTasks: tasks,
                dailyState: dailyState
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func suggestedMainTask() -> TaskItem? {
        MainTaskRecommendationService.recommendedTask(
            from: tasks,
            energyLevel: selectedEnergyLevel
        )
    }

    private func refreshMainTaskFromState() {
        guard let mainTaskId = dailyState?.mainTaskId else {
            mainTask = nil
            return
        }

        guard let selectedTask = tasks.first(where: { $0.id == mainTaskId }) else {
            clearMainTaskSelection()
            saveContext()
            return
        }

        mainTask = selectedTask
    }

    private func clearMainTaskSelection() {
        dailyState?.mainTaskId = nil
        mainTask = nil
    }

    private func activeTasks(
        from allTasks: [TaskItem],
        summaries: [DailySummary],
        referenceDate: Date
    ) -> [TaskItem] {
        let todayStart = calendar.startOfDay(for: referenceDate)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)
        let closedDays = Set(
            summaries
                .filter(\.isDayFinished)
                .map { calendar.startOfDay(for: $0.date) }
        )
        let isTodayClosed = closedDays.contains(todayStart)

        return allTasks.filter { task in
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

    private func shouldShowTask(
        _ task: TaskItem,
        taskDay: Date,
        closedDays: Set<Date>
    ) -> Bool {
        task.isCompleted == false || closedDays.contains(taskDay) == false
    }

    private func makeStreakCelebrationIfNeeded() -> StreakCelebration? {
        let today = calendar.startOfDay(for: Date())
        guard wasStreakCelebrationShownToday(today) == false,
              let completedCountsByDay = makeCompletedCountsByDay(),
              completedCountsByDay[today, default: 0] == 0 else {
            return nil
        }

        var productiveDays = Set(completedCountsByDay.filter { $0.value > 0 }.map(\.key))
        productiveDays.insert(today)
        let streakLength = calculateCurrentStreak(productiveDays: productiveDays, today: today)

        guard streakLength >= 1 else { return nil }
        return StreakCelebration(dayCount: streakLength)
    }

    private func makeCompletedCountsByDay() -> [Date: Int]? {
        guard let modelContext else { return nil }

        do {
            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(taskDescriptor)
            let summaryDescriptor = FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
            let summaries = try modelContext.fetch(summaryDescriptor)
            let today = calendar.startOfDay(for: Date())
            var counts: [Date: Int] = [:]

            for task in allTasks where task.isCompleted {
                let day = calendar.startOfDay(for: task.date)
                guard day <= today else { continue }
                counts[day, default: 0] += 1
            }

            for summary in summaries {
                let day = calendar.startOfDay(for: summary.date)
                guard day <= today else { continue }
                counts[day] = max(counts[day, default: 0], summary.completedTasksCount)
            }

            return counts
        } catch {
            statusMessage = error.localizedDescription
            return nil
        }
    }

    private func calculateCurrentStreak(
        productiveDays: Set<Date>,
        today: Date
    ) -> Int {
        var streak = 0
        var checkedDay = today

        while productiveDays.contains(checkedDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkedDay) else {
                break
            }
            checkedDay = previousDay
        }

        return streak
    }

    private func wasStreakCelebrationShownToday(_ today: Date) -> Bool {
        guard let lastShownDate = UserDefaults.standard.object(
            forKey: UserDefaultsKeys.lastStreakCelebrationDay
        ) as? Date else {
            return false
        }

        return calendar.isDate(lastShownDate, inSameDayAs: today)
    }

    private func markStreakCelebrationShownToday() {
        UserDefaults.standard.set(
            calendar.startOfDay(for: Date()),
            forKey: UserDefaultsKeys.lastStreakCelebrationDay
        )
    }

    @discardableResult
    private func saveContext(processRecurringTasks: Bool = false) -> Bool {
        guard let modelContext else { return false }

        do {
            try modelContext.save()
            if processRecurringTasks {
                try RecurringTaskService.process(
                    modelContext: modelContext,
                    calendar: calendar,
                    referenceDate: Date()
                )
            }
            WidgetSnapshotService.refresh(modelContext: modelContext, calendar: calendar)
            return true
        } catch {
            statusMessage = error.localizedDescription
            return false
        }
    }
}
