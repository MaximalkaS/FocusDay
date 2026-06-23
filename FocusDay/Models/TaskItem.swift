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
    var estimatedMinutes: Int
    var categoryRawValue: String

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .personal }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        date: Date = Date(),
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        estimatedMinutes: Int = 30,
        category: TaskCategory = .personal
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.date = date
        self.priorityRawValue = priority.rawValue
        self.isCompleted = isCompleted
        self.estimatedMinutes = estimatedMinutes
        self.categoryRawValue = category.rawValue
    }
}
