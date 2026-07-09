import Foundation
import SwiftData

@MainActor
final class CreateTaskViewModel: ObservableObject {
    @Published var title = ""
    @Published var taskDescription = ""
    @Published var selectedCategory: TaskCategory = .personal
    @Published var selectedPriority: TaskPriority = .medium
    @Published var selectedDuration = 30
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

    func saveTask(modelContext: ModelContext) -> Bool {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedTitle.isEmpty == false else {
            validationMessage = LocalizedStrings.emptyTitleError
            return false
        }

        let cleanedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if let taskToEdit {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let taskDay = calendar.startOfDay(for: taskToEdit.date)

            taskToEdit.title = cleanedTitle
            taskToEdit.taskDescription = cleanedDescription
            taskToEdit.priority = selectedPriority
            taskToEdit.estimatedMinutes = selectedDuration
            taskToEdit.category = selectedCategory

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

            modelContext.insert(task)
        }

        do {
            try modelContext.save()
            reset()
            return true
        } catch {
            validationMessage = error.localizedDescription
            return false
        }
    }

    private func reset() {
        title = ""
        taskDescription = ""
        selectedCategory = .personal
        selectedPriority = .medium
        selectedDuration = 30
        validationMessage = nil
    }
}
