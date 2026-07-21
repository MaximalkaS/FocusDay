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

        var recurringTaskToUpdate: TaskItem?

        if let taskToEdit {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let taskDay = calendar.startOfDay(for: taskToEdit.date)
            let repeatSettingsChanged = taskToEdit.isRepeating != isRepeating
                || taskToEdit.repeatType != (isRepeating ? selectedRepeatType : .none)
                || Set(taskToEdit.repeatWeekdays) != selectedRepeatWeekdays

            taskToEdit.title = cleanedTitle
            taskToEdit.taskDescription = cleanedDescription
            taskToEdit.priority = selectedPriority
            taskToEdit.estimatedMinutes = selectedDuration
            taskToEdit.category = selectedCategory

            if taskToEdit.isRepeating && isRepeating == false {
                do {
                    try RecurringTaskService.disableSeries(
                        for: taskToEdit,
                        modelContext: modelContext,
                        calendar: calendar
                    )
                } catch {
                    validationMessage = error.localizedDescription
                    return false
                }
            }

            applyRepeatSettings(
                to: taskToEdit,
                startDate: repeatSettingsChanged ? today : nil,
                resetScheduleAnchor: repeatSettingsChanged
            )

            if taskDay < today, taskToEdit.isCompleted == false {
                taskToEdit.date = Date()
            }
            recurringTaskToUpdate = taskToEdit.isRepeating ? taskToEdit : nil
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
            recurringTaskToUpdate = task.isRepeating ? task : nil
        }

        do {
            if let recurringTaskToUpdate {
                try RecurringTaskService.updateSeries(
                    from: recurringTaskToUpdate,
                    modelContext: modelContext
                )
            }
            try modelContext.save()
            try RecurringTaskService.process(modelContext: modelContext)
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

    private func applyRepeatSettings(
        to task: TaskItem,
        startDate: Date? = nil,
        resetScheduleAnchor: Bool = false
    ) {
        let effectiveRepeatType: TaskRepeatType = isRepeating ? selectedRepeatType : .none
        let effectiveWeekdays = effectiveRepeatType == .customDays
            ? Array(selectedRepeatWeekdays)
            : []

        task.isRepeating = isRepeating
        task.repeatType = effectiveRepeatType
        task.repeatWeekdays = effectiveWeekdays

        if isRepeating {
            let calendar = Calendar.current
            let anchorDate = calendar.startOfDay(for: startDate ?? task.date)
            if resetScheduleAnchor || task.repeatStartDate == nil {
                task.repeatStartDate = anchorDate
            }
            task.repeatSeriesId = task.repeatSeriesId ?? task.id
            if resetScheduleAnchor || task.scheduledDate == nil {
                task.scheduledDate = anchorDate
            }
            if effectiveRepeatType == .weekly {
                if resetScheduleAnchor || task.repeatAnchorWeekday == nil {
                    task.repeatAnchorWeekday = RepeatWeekday.from(
                        date: anchorDate,
                        calendar: calendar
                    )
                }
            } else {
                task.repeatAnchorWeekday = nil
            }
        } else {
            task.clearRecurrenceMetadata()
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
