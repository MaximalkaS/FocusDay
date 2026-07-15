import Foundation

enum FocusDayWidgetConstants {
    static let appGroupIdentifier = "group.com.maximka.focusday.mvp"
    static let snapshotKey = "focusDay.widgetSnapshot"
    static let userPlanKey = "focusDay.userPlan"
    static let completedMainTaskDisplayTaskIdKey = "focusDay.completedMainTaskDisplayTaskId"
    static let completedMainTaskDisplayUntilKey = "focusDay.completedMainTaskDisplayUntil"
    static let completedMainTaskDisplayDuration: TimeInterval = 3
}

struct FocusDayWidgetTask: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let categoryTitle: String
    let priorityTitle: String
    let priorityRawValue: String
    let isCompleted: Bool

    init(
        id: UUID,
        title: String,
        categoryTitle: String,
        priorityTitle: String,
        priorityRawValue: String,
        isCompleted: Bool
    ) {
        self.id = id
        self.title = title
        self.categoryTitle = categoryTitle
        self.priorityTitle = priorityTitle
        self.priorityRawValue = priorityRawValue
        self.isCompleted = isCompleted
    }
}

struct FocusDayWidgetSnapshot: Codable, Hashable {
    let updatedAt: Date
    let mainTask: FocusDayWidgetTask?
    let additionalTasks: [FocusDayWidgetTask]
    let completedTodayCount: Int
    let totalTodayCount: Int
    let availableTaskCount: Int
    let currentStreak: Int
    let isPremium: Bool
    let completedMainTaskDisplayUntil: Date?

    static let empty = FocusDayWidgetSnapshot(
        updatedAt: Date(),
        mainTask: nil,
        additionalTasks: [],
        completedTodayCount: 0,
        totalTodayCount: 0,
        availableTaskCount: 0,
        currentStreak: 0,
        isPremium: false,
        completedMainTaskDisplayUntil: nil
    )

    func hidingCompletedMainTask() -> FocusDayWidgetSnapshot {
        FocusDayWidgetSnapshot(
            updatedAt: updatedAt,
            mainTask: nil,
            additionalTasks: additionalTasks,
            completedTodayCount: completedTodayCount,
            totalTodayCount: totalTodayCount,
            availableTaskCount: availableTaskCount,
            currentStreak: currentStreak,
            isPremium: isPremium,
            completedMainTaskDisplayUntil: nil
        )
    }
}

enum FocusDayWidgetStorage {
    static func sharedDefaults() -> UserDefaults {
        UserDefaults(suiteName: FocusDayWidgetConstants.appGroupIdentifier) ?? .standard
    }

    static func saveSnapshot(_ snapshot: FocusDayWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults().set(data, forKey: FocusDayWidgetConstants.snapshotKey)
    }

    static func loadSnapshot() -> FocusDayWidgetSnapshot {
        guard let data = sharedDefaults().data(forKey: FocusDayWidgetConstants.snapshotKey),
              let snapshot = try? JSONDecoder().decode(FocusDayWidgetSnapshot.self, from: data) else {
            return .empty
        }

        return snapshot
    }

    static func savePlan(_ rawValue: String) {
        sharedDefaults().set(rawValue, forKey: FocusDayWidgetConstants.userPlanKey)
    }

    static func saveCompletedMainTaskDisplay(taskId: UUID, until displayUntil: Date) {
        let defaults = sharedDefaults()
        defaults.set(taskId.uuidString, forKey: FocusDayWidgetConstants.completedMainTaskDisplayTaskIdKey)
        defaults.set(displayUntil, forKey: FocusDayWidgetConstants.completedMainTaskDisplayUntilKey)
    }

    static func completedMainTaskDisplay() -> (taskId: UUID, until: Date)? {
        let defaults = sharedDefaults()
        guard let taskIdString = defaults.string(forKey: FocusDayWidgetConstants.completedMainTaskDisplayTaskIdKey),
              let taskId = UUID(uuidString: taskIdString),
              let until = defaults.object(forKey: FocusDayWidgetConstants.completedMainTaskDisplayUntilKey) as? Date else {
            return nil
        }

        return (taskId, until)
    }

    static func clearCompletedMainTaskDisplay() {
        let defaults = sharedDefaults()
        defaults.removeObject(forKey: FocusDayWidgetConstants.completedMainTaskDisplayTaskIdKey)
        defaults.removeObject(forKey: FocusDayWidgetConstants.completedMainTaskDisplayUntilKey)
    }

    static func isPremiumPlan() -> Bool {
        sharedDefaults().string(forKey: FocusDayWidgetConstants.userPlanKey) == "premium"
    }
}
