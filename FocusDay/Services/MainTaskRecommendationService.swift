import Foundation

enum MainTaskRecommendationService {
    static func recommendedTask(
        from tasks: [TaskItem],
        energyLevel: EnergyLevel?
    ) -> TaskItem? {
        let unfinishedTasks = tasks.filter { $0.isCompleted == false }
        guard unfinishedTasks.isEmpty == false else { return nil }

        guard let energyLevel else {
            return fallbackRecommendedTask(from: unfinishedTasks)
        }

        switch energyLevel {
        case .low:
            let meaningfulShortTasks = unfinishedTasks.filter { $0.priority != .low }
            let pool = meaningfulShortTasks.isEmpty ? unfinishedTasks : meaningfulShortTasks
            return pool.sorted { firstTask, secondTask in
                if firstTask.estimatedMinutes == secondTask.estimatedMinutes {
                    return priorityOrDateSort(firstTask, secondTask)
                }
                return firstTask.estimatedMinutes < secondTask.estimatedMinutes
            }.first

        case .medium:
            return unfinishedTasks.sorted { firstTask, secondTask in
                if firstTask.priority.rank == secondTask.priority.rank {
                    if firstTask.estimatedMinutes == secondTask.estimatedMinutes {
                        return firstTask.date < secondTask.date
                    }
                    return firstTask.estimatedMinutes < secondTask.estimatedMinutes
                }
                return firstTask.priority.rank > secondTask.priority.rank
            }.first

        case .high:
            return unfinishedTasks.sorted { firstTask, secondTask in
                if firstTask.priority.rank == secondTask.priority.rank {
                    if firstTask.estimatedMinutes == secondTask.estimatedMinutes {
                        return firstTask.date < secondTask.date
                    }
                    return firstTask.estimatedMinutes > secondTask.estimatedMinutes
                }
                return firstTask.priority.rank > secondTask.priority.rank
            }.first
        }
    }

    private static func fallbackRecommendedTask(from tasks: [TaskItem]) -> TaskItem? {
        tasks.sorted(by: priorityOrDateSort).first
    }

    private static func priorityOrDateSort(_ firstTask: TaskItem, _ secondTask: TaskItem) -> Bool {
        if firstTask.priority.rank == secondTask.priority.rank {
            return firstTask.date < secondTask.date
        }
        return firstTask.priority.rank > secondTask.priority.rank
    }
}
