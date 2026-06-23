import Foundation
import SwiftData
import SwiftUI
import WidgetKit

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
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM yyyy 'г.'"
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
            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(taskDescriptor)
            tasks = allTasks.filter { calendar.isDate($0.date, inSameDayAs: Date()) }

            let stateDescriptor = FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
            let allStates = try modelContext.fetch(stateDescriptor)

            if let existingState = allStates.first(where: { calendar.isDate($0.date, inSameDayAs: Date()) }) {
                dailyState = existingState
            } else {
                let newState = DailyState(date: Date())
                modelContext.insert(newState)
                dailyState = newState
                saveContext()
            }

            selectedMood = dailyState?.mood ?? .calm
            selectedEnergyLevel = dailyState?.energyLevel ?? .medium
            refreshMainTaskFromState()
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
        FocusDayWidgetStore.saveMainTaskTitle(task.title)
        WidgetCenter.shared.reloadAllTimelines()
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

        modelContext.delete(task)

        do {
            try modelContext.save()
            loadToday()
            return true
        } catch {
            modelContext.rollback()
            statusMessage = error.localizedDescription
            loadToday()
            return false
        }
    }

    func toggleCompletion(for task: TaskItem) {
        task.isCompleted.toggle()

        if task.isCompleted, dailyState?.mainTaskId == task.id {
            clearMainTaskSelection()
        }

        saveContext()
        loadToday()
    }

    func toggleMainTaskCompletion() {
        guard let mainTask else { return }
        toggleCompletion(for: mainTask)
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
        let unfinishedTasks = tasks.filter { $0.isCompleted == false }
        guard unfinishedTasks.isEmpty == false else { return nil }

        switch selectedEnergyLevel {
        case .low:
            let meaningfulShortTasks = unfinishedTasks.filter { $0.priority != .low }
            let pool = meaningfulShortTasks.isEmpty ? unfinishedTasks : meaningfulShortTasks
            return pool.sorted { firstTask, secondTask in
                if firstTask.estimatedMinutes == secondTask.estimatedMinutes {
                    return firstTask.priority.rank > secondTask.priority.rank
                }
                return firstTask.estimatedMinutes < secondTask.estimatedMinutes
            }.first

        case .medium:
            return unfinishedTasks.sorted { firstTask, secondTask in
                if firstTask.priority.rank == secondTask.priority.rank {
                    return firstTask.estimatedMinutes < secondTask.estimatedMinutes
                }
                return firstTask.priority.rank > secondTask.priority.rank
            }.first

        case .high:
            return unfinishedTasks.sorted { firstTask, secondTask in
                if firstTask.priority.rank == secondTask.priority.rank {
                    return firstTask.estimatedMinutes > secondTask.estimatedMinutes
                }
                return firstTask.priority.rank > secondTask.priority.rank
            }.first
        }
    }

    private func refreshMainTaskFromState() {
        guard let mainTaskId = dailyState?.mainTaskId else {
            mainTask = nil
            FocusDayWidgetStore.saveMainTaskTitle(nil)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        guard let selectedTask = tasks.first(where: { $0.id == mainTaskId }),
              selectedTask.isCompleted == false else {
            clearMainTaskSelection()
            saveContext()
            return
        }

        mainTask = selectedTask

        FocusDayWidgetStore.saveMainTaskTitle(mainTask?.title)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func clearMainTaskSelection() {
        dailyState?.mainTaskId = nil
        mainTask = nil
        FocusDayWidgetStore.saveMainTaskTitle(nil)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveContext() {
        guard let modelContext else { return }

        do {
            try modelContext.save()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
