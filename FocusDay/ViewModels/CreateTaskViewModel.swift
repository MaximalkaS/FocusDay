import Foundation
import SwiftData

@MainActor
final class CreateTaskViewModel: ObservableObject {
    @Published var title = ""
    @Published var taskDescription = ""
    @Published var selectedCategory: TaskCategory = .personal
    @Published var selectedPriority: TaskPriority = .medium
    @Published var selectedDuration = 30
    @Published var isRepeating = false
    @Published var selectedRepeatType: TaskRepeatType = .daily
    @Published var selectedRepeatWeekdays: Set<RepeatWeekday> = []
    @Published var validationMessage: String?

    private let taskToEdit: TaskItem?

    let availableDurations = [5, 15, 30, 60, 90]

    init(task: TaskItem? = nil) {
        taskToEdit = task

        guard let task else { return }
        title = task.title
        taskDescription = task.taskDescription
        selectedCategory = task.category
        selectedPriority = task.priority
        selectedDuration = task.estimatedMinutes
        isRepeating = task.isRepeating
        selectedRepeatType = task.repeatType == .none ? .daily : task.repeatType
        selectedRepeatWeekdays = Set(task.repeatWeekdays)
    }

    var isEditing: Bool {
        taskToEdit != nil
    }

    var screenTitle: String {
        isEditing ? LocalizedStrings.editTask : LocalizedStrings.createTask
    }

    var canSave: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func saveTask(
        modelContext: ModelContext,
        canUseRepeatingTasks: Bool = true
    ) -> Bool {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedTitle.isEmpty == false else {
            validationMessage = LocalizedStrings.emptyTitleError
            return false
        }

        let cleanedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isRepeating == false || canUseRepeatingTasks else {
            validationMessage = LocalizedStrings.repeatingTasksPremiumMessage
            return false
        }

        guard isRepeatSelectionValid else {
            validationMessage = LocalizedStrings.repeatValidationMessage
            return false
        }

        if let taskToEdit {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let taskDay = calendar.startOfDay(for: taskToEdit.date)

            taskToEdit.title = cleanedTitle
            taskToEdit.taskDescription = cleanedDescription
            taskToEdit.priority = selectedPriority
            taskToEdit.estimatedMinutes = selectedDuration
            taskToEdit.category = selectedCategory
            applyRepeatSettings(to: taskToEdit)

            if taskDay < today, taskToEdit.isCompleted == false {
                taskToEdit.date = Date()
            }
        } else {
            let task = TaskItem(
                title: cleanedTitle,
                taskDescription: cleanedDescription,
                date: Date(),
                priority: selectedPriority,
                isCompleted: false,
                estimatedMinutes: selectedDuration,
                category: selectedCategory
            )
            applyRepeatSettings(to: task, startDate: task.date)

            modelContext.insert(task)
        }

        do {
            try modelContext.save()
            WidgetSnapshotService.refresh(modelContext: modelContext)
            reset()
            return true
        } catch {
            validationMessage = error.localizedDescription
            return false
        }
    }

    func toggleRepeatWeekday(_ weekday: RepeatWeekday) {
        if selectedRepeatWeekdays.contains(weekday) {
            selectedRepeatWeekdays.remove(weekday)
        } else {
            selectedRepeatWeekdays.insert(weekday)
        }
    }

    private var isRepeatSelectionValid: Bool {
        isRepeating == false || selectedRepeatType != .customDays || selectedRepeatWeekdays.isEmpty == false
    }

    private func applyRepeatSettings(to task: TaskItem, startDate: Date? = nil) {
        let effectiveRepeatType: TaskRepeatType = isRepeating ? selectedRepeatType : .none
        let effectiveWeekdays = effectiveRepeatType == .customDays
            ? Array(selectedRepeatWeekdays)
            : []

        task.isRepeating = isRepeating
        task.repeatType = effectiveRepeatType
        task.repeatWeekdays = effectiveWeekdays

        if isRepeating {
            task.repeatStartDate = task.repeatStartDate ?? startDate ?? task.date
            task.repeatSeriesId = task.repeatSeriesId ?? task.id
        } else {
            task.repeatStartDate = nil
            task.repeatSeriesId = nil
        }
    }

    private func reset() {
        title = ""
        taskDescription = ""
        selectedCategory = .personal
        selectedPriority = .medium
        selectedDuration = 30
        isRepeating = false
        selectedRepeatType = .daily
        selectedRepeatWeekdays = []
        validationMessage = nil
    }
}
