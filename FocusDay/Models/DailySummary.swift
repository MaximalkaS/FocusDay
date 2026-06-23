import Foundation
import SwiftData

@Model
final class DailySummary: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var completedTasksCount: Int
    var totalTasksCount: Int
    var reflectionText: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        completedTasksCount: Int = 0,
        totalTasksCount: Int = 0,
        reflectionText: String = ""
    ) {
        self.id = id
        self.date = date
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
        self.reflectionText = reflectionText
    }
}
