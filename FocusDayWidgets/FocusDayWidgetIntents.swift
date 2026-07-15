import AppIntents
import Foundation
import SwiftData
import WidgetKit

struct SelectRecommendedMainTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Choose Main Task"
    static var description = IntentDescription("Selects the recommended main task for today.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            let container = try FocusDayModelContainerFactory.makeModelContainer()
            let modelContext = ModelContext(container)
            try DailyFocusService.selectRecommendedMainTask(modelContext: modelContext)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            WidgetCenter.shared.reloadAllTimelines()
        }

        return .result()
    }
}

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks a FocusDay task as completed.")
    static var openAppWhenRun = false

    @Parameter(title: "Task ID")
    var taskId: String

    init() {
        taskId = ""
    }

    init(taskId: String) {
        self.taskId = taskId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: taskId) else {
            WidgetCenter.shared.reloadAllTimelines()
            return .result()
        }

        do {
            let container = try FocusDayModelContainerFactory.makeModelContainer()
            let modelContext = ModelContext(container)
            try DailyFocusService.completeTask(id: id, modelContext: modelContext)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            WidgetCenter.shared.reloadAllTimelines()
        }

        return .result()
    }
}
