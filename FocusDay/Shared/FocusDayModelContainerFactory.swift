import Foundation
import SwiftData

enum FocusDayModelContainerFactory {
    static let schema = Schema([
        TaskItem.self,
        RecurringTaskSeries.self,
        DailyState.self,
        DailySummary.self
    ])

    static func makeModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(FocusDayWidgetConstants.appGroupIdentifier),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
