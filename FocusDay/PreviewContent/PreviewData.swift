import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static func previewContainer() -> ModelContainer {
        makeContainer(shouldSeed: true)
    }

    static func longListPreviewContainer() -> ModelContainer {
        let container = makeContainer(shouldSeed: true)
        seedLongList(container.mainContext)
        return container
    }

    static func emptyPreviewContainer() -> ModelContainer {
        makeContainer(shouldSeed: false)
    }

    static func progressSingleTaskContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [0: 1])
    }

    static func progressMultipleTasksContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [0: 3])
    }

    static func progressStreakContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-4: 1, -3: 2, -2: 1, -1: 3, 0: 2])
    }

    static func progressTodayOutlineOnlyContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-2: 1, -1: 2, 0: 1])
    }

    static func progressAfterDayChangeContainer() -> ModelContainer {
        let container = makeContainer(shouldSeed: false)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let completedTask = TaskItem(
            title: "Вчерашний завершённый фокус",
            date: yesterday,
            priority: .high,
            isCompleted: true,
            estimatedMinutes: 45,
            category: .work
        )
        let unfinishedTask = TaskItem(
            title: "Незавершённая задача переносится на сегодня",
            date: yesterday,
            priority: .medium,
            estimatedMinutes: 30,
            category: .personal
        )

        container.mainContext.insert(completedTask)
        container.mainContext.insert(unfinishedTask)
        container.mainContext.insert(
            DailyState(
                date: yesterday,
                energyLevel: .medium,
                mood: .calm,
                mainTaskId: completedTask.id
            )
        )
        savePreviewContext(container.mainContext)
        return container
    }

    static func progressStreakWarningContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-3: 1, -2: 2, -1: 1])
    }

    static func progressStreakCompletedTodayContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-2: 1, -1: 1, 0: 1])
    }

    static func progressZeroStreakContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [:])
    }

    static func progressMissedDayResetContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-4: 1, -3: 2])
    }

    static func progressFilledWeekContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-6: 2, -5: 3, -4: 1, -3: 4, -2: 2, -1: 5, 0: 3])
    }

    static func progressNewBestResultContainer() -> ModelContainer {
        progressContainer(completedCountsByDayOffset: [-6: 1, -5: 2, -4: 1, -3: 3, -2: 2, -1: 4, 0: 8])
    }

    private static func makeContainer(shouldSeed: Bool) -> ModelContainer {
        let schema = Schema([
            TaskItem.self,
            RecurringTaskSeries.self,
            DailyState.self,
            DailySummary.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if shouldSeed {
                seed(container.mainContext)
            }
            return container
        } catch {
            fatalError("Unable to create preview container: \(error)")
        }
    }

    private static func seed(_ context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        let firstTask = TaskItem(
            title: "Подготовить конспект",
            taskDescription: "Один короткий блок без перегруза",
            date: today,
            priority: .high,
            estimatedMinutes: 30,
            category: .study
        )
        let secondTask = TaskItem(
            title: "Прогулка",
            taskDescription: "Спокойные 15 минут",
            date: today,
            priority: .medium,
            isCompleted: true,
            estimatedMinutes: 15,
            category: .sport
        )
        let thirdTask = TaskItem(
            title: "Разобрать почту",
            date: today,
            priority: .low,
            estimatedMinutes: 15,
            category: .work
        )

        context.insert(firstTask)
        context.insert(secondTask)
        context.insert(thirdTask)
        context.insert(
            DailyState(
                date: today,
                energyLevel: .medium,
                mood: .calm,
                mainTaskId: firstTask.id
            )
        )

        for offset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                continue
            }

            let completedCount = max(0, offset + 7)
            context.insert(
                DailySummary(
                    date: date,
                    completedTasksCount: completedCount,
                    totalTasksCount: max(completedCount, 3),
                    reflectionText: "Preview"
                )
            )
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Unable to save preview data: \(error)")
        }
    }

    private static func seedLongList(_ context: ModelContext) {
        let extraTasks = [
            TaskItem(
                title: "Ответить на важные письма",
                taskDescription: "Только сообщения, требующие решения сегодня",
                priority: .medium,
                estimatedMinutes: 30,
                category: .work
            ),
            TaskItem(
                title: "Повторить материал занятия",
                priority: .low,
                estimatedMinutes: 15,
                category: .study
            ),
            TaskItem(
                title: "Составить подробный план большого проекта на следующую неделю",
                taskDescription: "Разделить результат на небольшие проверяемые шаги",
                priority: .high,
                estimatedMinutes: 90,
                category: .work
            ),
            TaskItem(
                title: "Вечерняя прогулка",
                priority: .low,
                estimatedMinutes: 30,
                category: .personal
            ),
            TaskItem(
                title: "Тренировка",
                priority: .medium,
                estimatedMinutes: 60,
                category: .sport
            )
        ]

        extraTasks.forEach(context.insert)

        do {
            try context.save()
        } catch {
            assertionFailure("Unable to save long preview data: \(error)")
        }
    }

    private static func progressContainer(
        completedCountsByDayOffset: [Int: Int]
    ) -> ModelContainer {
        let container = makeContainer(shouldSeed: false)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for (offset, count) in completedCountsByDayOffset {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                continue
            }

            for index in 0..<count {
                container.mainContext.insert(
                    TaskItem(
                        title: "Задача \(index + 1)",
                        date: date,
                        priority: TaskPriority.allCases[index % TaskPriority.allCases.count],
                        isCompleted: true,
                        category: .personal
                    )
                )
            }
        }

        do {
            try container.mainContext.save()
        } catch {
            assertionFailure("Unable to save progress preview data: \(error)")
        }

        return container
    }

    private static func savePreviewContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("Unable to save preview context: \(error)")
        }
    }
}
