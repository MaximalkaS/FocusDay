import Foundation
import SwiftData

struct DailyProgressPoint: Identifiable, Equatable {
    let date: Date
    let completedCount: Int

    var id: Date { date }
}

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var completedTasksCount = 0
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestResult = 0
    @Published private(set) var lastSevenDays: [DailyProgressPoint] = []
    @Published private(set) var productiveDays: Set<Date> = []
    @Published var statusMessage: String?

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func load(modelContext: ModelContext) {
        do {
            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
            let tasks = try modelContext.fetch(taskDescriptor)
            recalculate(tasks: tasks)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func recalculate(tasks: [TaskItem]) {
        let completedPerDay = makeCompletedCountsByDay(tasks: tasks)

        completedTasksCount = tasks.filter(\.isCompleted).count
        productiveDays = Set(completedPerDay.filter { $0.value > 0 }.map(\.key))
        currentStreak = calculateCurrentStreak(productiveDays: productiveDays)
        bestResult = completedPerDay.values.max() ?? 0
        lastSevenDays = makeLastSevenDays(from: completedPerDay)
        statusMessage = nil
    }

    private func makeCompletedCountsByDay(tasks: [TaskItem]) -> [Date: Int] {
        var counts: [Date: Int] = [:]

        for task in tasks where task.isCompleted {
            let day = calendar.startOfDay(for: task.date)
            counts[day, default: 0] += 1
        }

        return counts
    }

    private func calculateCurrentStreak(productiveDays: Set<Date>) -> Int {
        var streak = 0
        var checkedDay = calendar.startOfDay(for: Date())

        while productiveDays.contains(checkedDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkedDay) else {
                break
            }
            checkedDay = previousDay
        }

        return streak
    }

    private func makeLastSevenDays(from completedPerDay: [Date: Int]) -> [DailyProgressPoint] {
        let today = calendar.startOfDay(for: Date())

        return (-6...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }

            return DailyProgressPoint(
                date: date,
                completedCount: completedPerDay[date, default: 0]
            )
        }
    }
}
