import Foundation

enum LocalizedStrings {
    static let appName = "FocusDay"
    static let appSubtitle = "Один спокойный фокус на день"
    static let start = "Начать"
    static let continueTitle = "Продолжить"
    static let save = "Сохранить"
    static let cancel = "Отмена"
    static let done = "Готово"
    static let add = "Добавить"
    static let edit = "Изменить"
    static let today = "Сегодня"
    static let progress = "Прогресс"
    static let settings = "Настройки"
    static let eveningSummary = "Вечерний итог"
    static let createTask = "Новая задача"
    static let editTask = "Редактировать задачу"
    static let todayTab = "Сегодня"
    static let progressTab = "Прогресс"
    static let settingsTab = "Настройки"
    static let todaySubtitle = "Один ясный фокус без лишней нагрузки"
    static let progressSubtitle = "Небольшие шаги складываются в устойчивый ритм"
    static let settingsSubtitle = "Настройте цель и время напоминаний"
    static let createTaskSubtitle = "Добавьте только то, что действительно важно"
    static let eveningSummarySubtitle = "Зафиксируйте результат и спокойно завершите день"

    static let onboardingWelcomeTitle = "FocusDay"
    static let onboardingWelcomeText = "Выбирайте одно главное дело дня и держите нагрузку под контролем."
    static let onboardingGoalTitle = "Основная цель"
    static let onboardingReminderTitle = "Напоминания"
    static let onboardingNameTitle = "Как к тебе обращаться?"
    static let namePlaceholder = "Ваше имя"
    static let profile = "Профиль"
    static let morningReminder = "Утреннее"
    static let eveningReminder = "Вечернее"

    static let goalStudy = "Учёба"
    static let goalSport = "Спорт"
    static let goalWork = "Работа"
    static let goalHabits = "Привычки"
    static let goalPersonal = "Личные дела"

    static let greeting = "Доброе утро! ☀️"
    static let moodTitle = "Как вы себя чувствуете?"
    static let energyTitle = "Уровень энергии"
    static let lowEnergy = "Низкий"
    static let mediumEnergy = "Средний"
    static let highEnergy = "Высокий"
    static let calmMood = "Спокойно"
    static let tiredMood = "Усталость"
    static let motivatedMood = "Мотивация"
    static let anxiousMood = "Тревожно"
    static let mainTaskOfDay = "Главное дело дня"
    static let mainTaskBadge = "Главное"
    static let noMainTask = "Пока главное дело не выбрано"
    static let chooseMainTask = "Выбрать главное дело"
    static let makeMainTask = "Сделать главным"
    static let additionalTasks = "Дополнительные задачи"
    static let noAdditionalTasks = "Добавьте пару задач, а FocusDay поможет выбрать главное."
    static let addTask = "Добавить задачу"
    static let taskProgress = "Прогресс дня"
    static let goToEveningSummary = "Перейти к итогу"
    static let markCompleted = "Отметить выполненной"
    static let markNotCompleted = "Вернуть в работу"

    static let taskTitlePlaceholder = "Название"
    static let taskDescriptionPlaceholder = "Описание"
    static let category = "Категория"
    static let priority = "Приоритет"
    static let duration = "Длительность"
    static let emptyTitleError = "Нельзя сохранить задачу без названия."
    static let lowPriority = "Низкий"
    static let mediumPriority = "Средний"
    static let highPriority = "Высокий"
    static let minutes5 = "5 мин"
    static let minutes15 = "15 мин"
    static let minutes30 = "30 мин"
    static let minutes60 = "60 мин"
    static let minutes90 = "90 мин"

    static let productiveDays = "Продуктивные дни"
    static let completedTasks = "Завершено задач"
    static let currentStreak = "Текущая серия"
    static let bestResult = "Лучший результат"
    static let lastSevenDays = "Последние 7 дней"
    static let daysSuffix = "дн."

    static let eveningQuestion = "Удалось ли выполнить главное дело дня?"
    static let whatWorkedToday = "Что получилось сегодня?"
    static let reflectionPlaceholder = "Коротко запишите, что помогло."
    static let supportiveMessage = "Отлично. День зафиксирован, завтра будет легче начать."
    static let savingProgress = "Сохранение прогресса..."
    static let changesSaved = "Изменения сохранены"
    static let deleteTaskTitle = "Удалить задачу?"
    static let deleteTaskMessage = "Это действие нельзя отменить."
    static let delete = "Удалить"
    static let deleteTaskAction = "Удалить"
    static let taskActions = "Действия с задачей"
    static let removeFromMainTasks = "Убрать из главных"

    static let notifications = "Уведомления"
    static let notificationSaved = "Напоминания обновлены."
    static let morningNotificationBody = "Выбери главное дело дня"
    static let eveningNotificationBody = "Подведи короткий итог дня"
    static let selectedGoal = "Выбранная цель"

    static func personalizedGreeting(_ name: String) -> String {
        "Доброе утро, \(name)! ☀️"
    }

    static let widgetTitle = "Фокус дня"
    static let widgetEmptyTitle = "Главное дело ещё не выбрано"
    static let widgetPrompt = "Откройте FocusDay утром"

    static let aiPlanPlaceholder = "AI-планировщик будет добавлен позже"

    static let weekdayShortTitles = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    static func completedOutOfTotal(_ completed: Int, _ total: Int) -> String {
        "\(completed) из \(total)"
    }

    static func completedTasksCount(_ count: Int) -> String {
        "\(count)"
    }

    static func minutes(_ value: Int) -> String {
        "\(value) мин"
    }
}
