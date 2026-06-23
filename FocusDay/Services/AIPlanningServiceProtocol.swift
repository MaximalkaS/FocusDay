import Foundation

struct DayPlanSuggestion: Equatable {
    let mainTaskTitle: String
    let additionalTaskTitles: [String]
    let note: String
}

protocol AIPlanningServiceProtocol {
    func makePlan(from rawText: String, currentTasks: [TaskItem], dailyState: DailyState?) async throws -> DayPlanSuggestion
}

enum AIPlanningError: Error {
    case emptyInput
}

final class PlaceholderAIPlanningService: AIPlanningServiceProtocol {
    func makePlan(from rawText: String, currentTasks: [TaskItem], dailyState: DailyState?) async throws -> DayPlanSuggestion {
        let cleanedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedText.isEmpty == false else {
            throw AIPlanningError.emptyInput
        }

        return DayPlanSuggestion(
            mainTaskTitle: cleanedText,
            additionalTaskTitles: currentTasks.map(\.title),
            note: LocalizedStrings.aiPlanPlaceholder
        )
    }
}
