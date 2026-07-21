import Foundation

enum LocalizedStrings {
    private static var isRussian: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ru") ?? false
    }

    static var dateLocale: Locale {
        Locale(identifier: isRussian ? "ru_RU" : "en_US")
    }

    static var compactDateFormat: String {
        isRussian ? "EEEE, d MMMM" : "EEEE, MMMM d"
    }

    static var fullDateFormat: String {
        isRussian ? "EEEE, d MMMM yyyy 'г.'" : "EEEE, MMMM d, yyyy"
    }

    private static func text(_ ru: String, _ en: String) -> String {
        isRussian ? ru : en
    }

    static let appName = "FocusDay"
    static let appSubtitle = text("Один спокойный фокус на день", "One calm focus for the day")
    static let start = text("Начать", "Start")
    static let continueTitle = text("Продолжить", "Continue")
    static let save = text("Сохранить", "Save")
    static let cancel = text("Отмена", "Cancel")
    static let back = text("Назад", "Back")
    static let done = text("Готово", "Done")
    static let add = text("Добавить", "Add")
    static let edit = text("Изменить", "Edit")
    static let today = text("Сегодня", "Today")
    static let progress = text("Прогресс", "Progress")
    static let settings = text("Настройки", "Settings")
    static let eveningSummary = text("Завершение дня", "Day Completion")
    static let createTask = text("Новая задача", "New Task")
    static let editTask = text("Редактировать задачу", "Edit Task")
    static let todayTab = text("Сегодня", "Today")
    static let progressTab = text("Прогресс", "Progress")
    static let settingsTab = text("Настройки", "Settings")
    static let todaySubtitle = text("Один ясный фокус без лишней нагрузки", "One clear focus without overload")
    static let progressSubtitle = text("Следите за фокусом и своими результатами", "Track your focus and results")
    static let settingsSubtitle = text("Настройте приложение под себя", "Make the app fit your routine")
    static let createTaskSubtitle = text("Добавьте только то, что действительно важно", "Add only what truly matters")
    static let eveningSummarySubtitle = text("Завершите сегодняшний день и сохраните его результаты", "Finish today and save its results")
    static let storageUnavailableTitle = text("Хранилище недоступно", "Storage Unavailable")
    static let storageUnavailableMessage = text(
        "Не удалось открыть локальные данные FocusDay. Перезапустите приложение или освободите место на устройстве.",
        "Could not open FocusDay local data. Restart the app or free up space on your device."
    )

    static let onboardingWelcomeTitle = "FocusDay"
    static let onboardingWelcomeText = text(
        "Выбирайте одно главное дело дня\nи держите нагрузку под контролем",
        "Choose one main task for the day\nand keep your workload under control"
    )
    static let onboardingGoalTitle = text("Основная цель", "Main Goal")
    static let onboardingReminderTitle = text("Напоминания", "Reminders")
    static let onboardingNameTitle = text("Как к вам обращаться?", "What should we call you?")
    static let onboardingIntroWelcomeSubtitle = text(
        "Один день. Одно главное дело.\nМеньше перегрузки — больше результата.",
        "One day. One main task.\nLess overload — more results."
    )
    static let onboardingIntroHowTitle = text("Как работает FocusDay", "How FocusDay Works")
    static let onboardingIntroHowSubtitle = text(
        "Всего несколько простых шагов,\nкоторые помогут сохранять фокус\nкаждый день.",
        "Just a few simple steps\nto help you keep focus\nevery day."
    )
    static let onboardingIntroMainTaskTitle = text("Главное дело дня", "Main Task of the Day")
    static let onboardingIntroMainTaskText = text(
        "Выберите одну самую важную\nзадачу и сосредоточьтесь\nименно на ней.",
        "Choose one most important\ntask and focus exactly\non it."
    )
    static let onboardingIntroProgressTitle = text("Следите за прогрессом", "Track Your Progress")
    static let onboardingIntroProgressText = text(
        "Выполняйте задачи, сохраняйте\nсерию и наблюдайте свой\nежедневный рост.",
        "Complete tasks, keep your\nstreak, and watch your\ndaily growth."
    )
    static let onboardingIntroEveningTitle = text("Завершение дня", "Day Completion")
    static let onboardingIntroEveningText = text(
        "Каждый вечер завершайте день,\nсохраняйте результаты и\nпостепенно улучшайте фокус.",
        "Finish each day,\nsave your results, and\ngradually improve your focus."
    )
    static let onboardingIntroPremiumTitle = text("Получите больше\nвозможностей", "Get More\nPossibilities")
    static let onboardingIntroPremiumSubtitle = text(
        "Все основные функции доступны бесплатно.\nPremium открывает дополнительные\nвозможности для тех, кто хочет получить\nмаксимум от FocusDay.",
        "All core features are available for free.\nPremium unlocks additional\npossibilities for those who want to get\nthe most from FocusDay."
    )
    static let onboardingIntroAllHistoryTitle = text("История за всё время", "All-Time History")
    static let onboardingIntroAllHistoryText = text(
        "Просматривайте всю историю\nвыполненных задач.",
        "View your complete history\nof completed tasks."
    )
    static let onboardingIntroSearchTitle = text("Поиск и фильтры", "Search and Filters")
    static let onboardingIntroSearchText = text("Быстро находите нужные задачи.", "Quickly find the tasks you need.")
    static let onboardingIntroWidgetsTitle = text("Дополнительные виджеты", "Additional Widgets")
    static let onboardingIntroWidgetsText = text(
        "Получите ещё больше вариантов\nвиджетов для рабочего стола.",
        "Get even more widget options\nfor your Home Screen."
    )
    static let onboardingIntroFuturePremiumTitle = text("Все будущие Premium-функции", "All Future Premium Features")
    static let onboardingIntroFuturePremiumText = text(
        "Все новые Premium-возможности\nбудут доступны автоматически.",
        "All new Premium features\nwill be available automatically."
    )
    static let onboardingIntroTryPremium = text("Попробовать Premium", "Try Premium")
    static let onboardingIntroContinueFree = text("Продолжить бесплатно", "Continue for Free")
    static func onboardingIntroPageIndicator(_ current: Int, _ total: Int) -> String {
        text("Страница \(current) из \(total)", "Page \(current) of \(total)")
    }
    static let namePlaceholder = text("Ваше имя", "Your name")
    static let profile = text("Профиль", "Profile")
    static let morningReminder = text("Утреннее", "Morning")
    static let eveningReminder = text("Вечернее", "Evening")
    static let morningReminderTitle = text("Утреннее напоминание", "Morning Reminder")
    static let eveningReminderTitle = text("Вечернее напоминание", "Evening Reminder")
    static let morningReminderSubtitle = text("Выбрать главное дело дня", "Choose your main task")
    static let eveningReminderSubtitle = text("Завершить день", "Finish your day")

    static let goalStudy = text("Учёба", "Study")
    static let goalSport = text("Спорт", "Sport")
    static let goalWork = text("Работа", "Work")
    static let goalHabits = text("Привычки", "Habits")
    static let goalPersonal = text("Личные дела", "Personal")

    static let morningGreeting = text("Доброе утро", "Good morning")
    static let afternoonGreeting = text("Добрый день", "Good afternoon")
    static let eveningGreeting = text("Добрый вечер", "Good evening")
    static let moodTitle = text("Как вы себя чувствуете?", "How are you feeling?")
    static let moodExplanation = text(
        "Настроение помогает подобрать более комфортный темп дня и в будущем может использоваться для персональных рекомендаций.",
        "Your mood helps set a more comfortable pace and can support personal recommendations later."
    )
    static let energyTitle = text("Уровень энергии", "Energy Level")
    static let energyExplanation = text(
        "Уровень энергии влияет на подбор главного дела: при низкой энергии приложение предлагает короткие и более лёгкие задачи, а при высокой — более важные и объёмные.",
        "Your energy level affects the main-task suggestion: low energy favors shorter tasks, while high energy favors more important or larger ones."
    )
    static let lowEnergy = text("Низкий", "Low")
    static let mediumEnergy = text("Средний", "Medium")
    static let highEnergy = text("Высокий", "High")
    static let calmMood = text("Спокойно", "Calm")
    static let tiredMood = text("Усталость", "Tired")
    static let motivatedMood = text("Мотивация", "Motivated")
    static let anxiousMood = text("Тревожно", "Anxious")
    static let mainTaskOfDay = text("Главное дело дня", "Main Task of the Day")
    static let mainTaskBadge = text("Главное", "Main")
    static let noMainTask = text("Пока главное дело не выбрано", "No main task selected yet")
    static let chooseMainTask = text("Выбрать главное дело", "Choose Main Task")
    static let makeMainTask = text("Сделать главным", "Make Main")
    static let additionalTasks = text("Дополнительные задачи", "Additional Tasks")
    static let noAdditionalTasks = text(
        "Добавьте пару задач, а FocusDay поможет выбрать главное.",
        "Add a few tasks and FocusDay will help choose the main one."
    )
    static let addTask = text("Добавить задачу", "Add Task")
    static let taskProgress = text("Прогресс дня", "Day Progress")
    static let goToEveningSummary = text("Завершить день", "Finish Day")
    static let markCompleted = text("Отметить выполненной", "Mark as completed")
    static let markNotCompleted = text("Вернуть в работу", "Mark as active")

    static let taskTitlePlaceholder = text("Название", "Title")
    static let taskDescriptionPlaceholder = text("Описание", "Description")
    static let category = text("Категория", "Category")
    static let priority = text("Приоритет", "Priority")
    static let duration = text("Длительность", "Duration")
    static let repeatSectionTitle = text("Повторение", "Repeat")
    static let repeatSectionSubtitle = text(
        "Настройте, когда задача будет появляться снова",
        "Choose when this task should appear again"
    )
    static let repeatToggleLabel = text("Включить повторение", "Enable repeat")
    static let repeatNone = text("Без повторения", "No repeat")
    static let repeatEveryDay = text("Каждый день", "Every day")
    static let repeatWeekdays = text("По будням", "Weekdays")
    static let repeatWeekly = text("Раз в неделю", "Once a week")
    static let repeatCustomDays = text("Свои дни", "Custom days")
    static let repeatOnceInfo = text(
        "Задача будет создана только на сегодня",
        "This task will be created only for today"
    )
    static let repeatHowTitle = text("Как повторять?", "How should it repeat?")
    static let repeatDailyInfo = text(
        "Задача будет появляться каждый день",
        "This task will appear every day"
    )
    static let repeatWeekdaysInfo = text(
        "Задача будет появляться с понедельника по пятницу",
        "This task will appear Monday through Friday"
    )
    static let repeatWeeklyInfo = text(
        "Задача будет повторяться раз в неделю",
        "This task will repeat once a week"
    )
    static let repeatSelectDaysTitle = text("Выберите дни", "Choose days")
    static let repeatSelectAtLeastOneDay = text(
        "Выберите хотя бы один день",
        "Choose at least one day"
    )
    static let repeatValidationMessage = text(
        "Для повторения по своим дням выберите хотя бы один день.",
        "Choose at least one day for custom repeat."
    )
    static let repeatingTask = text("Повторяется", "Repeats")
    static let emptyTitleError = text("Нельзя сохранить задачу без названия.", "Task title cannot be empty.")
    static let lowPriority = text("Низкий", "Low")
    static let mediumPriority = text("Средний", "Medium")
    static let highPriority = text("Высокий", "High")
    static let minutes5 = text("5 мин", "5 min")
    static let minutes15 = text("15 мин", "15 min")
    static let minutes30 = text("30 мин", "30 min")
    static let minutes60 = text("60 мин", "60 min")
    static let minutes90 = text("90 мин", "90 min")

    static let productiveDays = text("Продуктивные дни", "Productive Days")
    static let completedTasks = text("Завершено задач", "Completed Tasks")
    static let currentStreak = text("Текущая серия", "Current Streak")
    static let currentStreakWarning = text(
        "Серия сбросится завтра, если сегодня не выполнить ни одной задачи",
        "Your streak will reset tomorrow if you do not complete a task today"
    )
    static let streakCelebrationStartTitle = text("Начало положено!", "Great Start!")
    static let streakCelebrationTitle = text("Серия продлена!", "Streak Extended!")
    static let streakCelebrationSubtitle = text(
        "Вы выполнили первую задачу сегодня",
        "You completed your first task today"
    )
    static let bestResult = text("Лучший результат", "Best Result")
    static let lastSevenDays = text("Последние 7 дней", "Last 7 Days")
    static let completedToday = text("Завершено сегодня", "Completed Today")
    static let calendarThirtyDays = text("Календарь месяца", "Monthly Calendar")
    static let progressDoneLegend = text("Выполнено", "Done")
    static let progressMissedLegend = text("Пропущено", "Missed")
    static let progressTodayLegend = text("Сегодня", "Today")
    static let activitySevenDays = text("Активность за неделю", "Weekly Activity")
    static let completedTasksLegend = text("Выполненные задачи", "Completed tasks")
    static let weeklyCompletedTasks = text("Завершённые задачи", "Completed Tasks")
    static let tasksWord = text("задачи", "tasks")
    static let unchanged = text("Без изменений", "No change")
    static let daysSuffix = text("дн.", "d")
    static let dayAxisTitle = text("День", "Day")
    static let tasksAxisTitle = text("Задачи", "Tasks")

    static let eveningQuestion = text("Удалось ли выполнить главное дело дня?", "Did you complete your main task?")
    static let whatWorkedToday = text("Что получилось сегодня?", "What went well today?")
    static let reflectionPlaceholder = text("Коротко запишите, что получилось", "Briefly write what went well")
    static let howWasYourDay = text("Как прошёл день?", "How was your day?")
    static let dayFeelingExcellent = text("Отлично", "Great")
    static let dayFeelingCalm = text("Спокойно", "Calm")
    static let dayFeelingHard = text("Непросто", "Difficult")
    static let dayFeelingOverloaded = text("Тяжело", "Hard day")
    static let whatAffectedDay = text("Что повлияло на день?", "What affected your day?")
    static let influenceNotEnoughTime = text("Не хватило времени", "Not enough time")
    static let influenceLowEnergy = text("Мало энергии", "Low energy")
    static let influenceDistracted = text("Отвлекался", "Got distracted")
    static let influenceTooManyTasks = text("Слишком много задач", "Too many tasks")
    static let dayNoteTitle = text("Заметка о дне", "Day Note")
    static let unfinishedTasksTitle = text("Незавершённые задачи", "Unfinished Tasks")
    static let finishDay = text("Завершить день", "Finish Day")
    static let dayCompleted = text("День завершён", "Day completed")
    static let supportiveMessage = text(
        "Отличная работа! Завтра продолжим двигаться к вашей цели.",
        "Great work! Tomorrow, we will keep moving toward your goal."
    )
    static let savingProgress = text("Сохранение прогресса...", "Saving progress...")
    static let changesSaved = text("Изменения сохранены", "Changes saved")
    static let deleteTaskTitle = text("Удалить задачу?", "Delete task?")
    static let deleteTaskMessage = text("Это действие нельзя отменить.", "This action cannot be undone.")
    static let delete = text("Удалить", "Delete")
    static let deleteTaskAction = text("Удалить", "Delete")
    static let taskActions = text("Действия с задачей", "Task actions")
    static let removeFromMainTasks = text("Убрать из главных", "Remove from main")

    static let notifications = text("Уведомления", "Notifications")
    static let notificationsSubtitle = text("Выберите удобное время для напоминаний", "Choose a convenient reminder time")
    static let notificationSaved = text("Напоминания обновлены.", "Reminders updated.")
    static let notificationScheduleError = text(
        "Не удалось включить уведомления. Проверьте разрешение в настройках iOS.",
        "Could not enable notifications. Check notification permissions in iOS Settings."
    )
    static let morningNotificationBody = text("Выбери главное дело дня", "Choose your main task for the day")
    static let eveningNotificationBody = text("Завершите день и сохраните результат", "Finish the day and save your result")
    static let selectedGoal = text("Выбранная цель", "Selected goal")
    static let saveChanges = text("Сохранить изменения", "Save Changes")
    static let testPlanTitle = text("Тестовый план", "Test Plan")
    static let testPlanSubtitle = text(
        "Временное переключение для проверки Premium-функций",
        "Temporary switch for testing Premium features"
    )
    static let freePlanTitle = text("Free", "Free")
    static let premiumPlanTitle = text("Premium", "Premium")
    static let premiumBadgeTitle = text("Premium", "Premium")
    static let premiumFeatureTitle = text("Premium-функция", "Premium Feature")
    static let premiumFeatureMessage = text(
        "Скоро здесь появится оформление подписки. Сейчас можно включить Premium в настройках для тестирования.",
        "Subscription setup will appear here later. For now, enable Premium in Settings for testing."
    )
    static let repeatingTasksPremiumMessage = text(
        "Повторяющиеся задачи доступны в Premium",
        "Repeating tasks are available in Premium"
    )
    static let premiumHistoryTitle = text("Доступно в Premium", "Available in Premium")
    static let thirtyDayHistoryPremiumMessage = text(
        "История за 30 дней доступна в Premium. Сейчас можно включить Premium в настройках для тестирования.",
        "30-day history is available in Premium. For now, enable Premium in Settings for testing."
    )
    static let allTimeHistoryPremiumMessage = text(
        "История за всё время доступна в Premium. Сейчас можно включить Premium в настройках для тестирования.",
        "All-time history is available in Premium. For now, enable Premium in Settings for testing."
    )
    static let historyFiltersPremiumMessage = text(
        "Фильтры по категории и приоритету доступны в Premium. Сейчас можно включить Premium в настройках для тестирования.",
        "Category and priority filters are available in Premium. For now, enable Premium in Settings for testing."
    )
    static let gotIt = text("Понятно", "Got it")
    static let toggleOn = text("Включено", "On")
    static let toggleOff = text("Выключено", "Off")
    static let all = text("Все", "All")
    static let history = text("История", "History")
    static let taskHistoryTitle = text("История задач", "Task History")
    static let taskHistorySubtitle = text("Все завершённые дела по дням", "All completed tasks by day")
    static let historyTodayPeriod = text("Сегодня", "Today")
    static let historySevenDaysPeriod = text("7 дней", "7 Days")
    static let historyThirtyDaysPeriod = text("30 дней", "30 Days")
    static let historyAllTimePeriod = text("Все время", "All Time")
    static let historySearchPlaceholder = text("Поиск...", "Search...")
    static let filters = text("Фильтры", "Filters")
    static let filtersSubtitle = text("Уточните, какие задачи показать", "Refine which tasks to show")
    static let resetFilters = text("Сбросить", "Reset")
    static let applyFilters = text("Применить", "Apply")
    static let tasksCompletedLower = text("задач выполнено", "tasks completed")
    static let excellentWork = text("Отличная работа!", "Great work!")
    static let historyForToday = text("За сегодня", "Today")
    static let historyForLast = text("За последние", "Last")
    static let historyForAllTime = text("За всё время", "All time")
    static let historyFilteredResults = text("По выбранным фильтрам", "By selected filters")
    static let noCompletedTasksTitle = text("Пока нет выполненных задач", "No completed tasks yet")
    static let noCompletedTasksSubtitle = text("Завершите первую задачу,\nи она появится здесь", "Complete your first task,\nand it will appear here")
    static let noHistoryResultsTitle = text("Ничего не найдено", "Nothing found")
    static let noHistoryResultsSubtitle = text(
        "Попробуйте изменить запрос или сбросить фильтры",
        "Try changing the search or resetting filters"
    )
    static let yesterday = text("Вчера", "Yesterday")

    static func personalizedGreeting(_ greeting: String, name: String) -> String {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedName.isEmpty == false else { return greeting }
        return "\(greeting), \(cleanedName)"
    }

    static let aiPlanPlaceholder = text(
        "AI-планировщик будет добавлен позже",
        "AI planner will be added later"
    )

    static var weekdayShortTitles: [String] {
        isRussian
            ? ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
            : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    static func completedOutOfTotal(_ completed: Int, _ total: Int) -> String {
        isRussian ? "\(completed) из \(total)" : "\(completed) of \(total)"
    }

    static func completedTasksCount(_ count: Int) -> String {
        "\(count)"
    }

    static func daysCount(_ count: Int) -> String {
        if isRussian {
            return "\(count) \(pluralForm(count, one: "день", few: "дня", many: "дней"))"
        }

        return "\(count) \(count == 1 ? "day" : "days")"
    }

    static func streakDaysInRow(_ count: Int) -> String {
        isRussian ? "\(daysCount(count)) подряд" : "\(daysCount(count)) in a row"
    }

    static func tasksCount(_ count: Int) -> String {
        if isRussian {
            return "\(count) \(pluralForm(count, one: "задача", few: "задачи", many: "задач"))"
        }

        return "\(count) \(count == 1 ? "task" : "tasks")"
    }

    static func unfinishedTasksMoveTomorrow(_ count: Int) -> String {
        if isRussian {
            let verb = abs(count) % 10 == 1 && abs(count) % 100 != 11 ? "перейдёт" : "перейдут"
            return "\(tasksCount(count)) автоматически \(verb) на завтра."
        }

        return "\(tasksCount(count)) will automatically move to tomorrow."
    }

    static func weeklyTasksCount(_ count: Int) -> String {
        isRussian ? "\(tasksCount(count)) за неделю" : "\(tasksCount(count)) this week"
    }

    static func weeklyMoreThanPrevious(_ count: Int) -> String {
        if isRussian {
            return "На \(tasksAccusativeCount(count)) больше, чем на прошлой неделе"
        }

        return "\(tasksCount(count)) more than last week"
    }

    static func weeklyMoreThanPreviousPill(_ count: Int) -> String {
        if isRussian {
            return "↑ На \(tasksAccusativeCount(count)) больше, чем на прошлой неделе"
        }

        return "↑ \(tasksCount(count)) more than last week"
    }

    static func weeklyLessThanPrevious(_ count: Int) -> String {
        if isRussian {
            return "На \(tasksAccusativeCount(count)) меньше, чем на прошлой неделе"
        }

        return "\(tasksCount(count)) fewer than last week"
    }

    static let weeklyEqualToPrevious = text(
        "Столько же, сколько на прошлой неделе",
        "Same as last week"
    )
    static let weeklySameAsPreviousPill = text(
        "Столько же задач, как на прошлой неделе",
        "Same number of tasks as last week"
    )
    static let weeklyCalmPaceMessage = text(
        "У каждой недели свой ритм. Даже небольшие шаги помогают двигаться к вашим целям.",
        "Every week has its own rhythm. Even small steps help you move toward your goals."
    )

    static func weeklyIncreaseBadge(_ count: Int) -> String {
        isRussian ? "↑ +\(count) к прошлой неделе" : "↑ +\(count) vs last week"
    }

    static func weeklyDecreaseBadge(_ count: Int) -> String {
        isRussian ? "↓ \(count) к прошлой неделе" : "↓ \(count) vs last week"
    }

    static func historyLastDays(_ days: Int) -> String {
        if isRussian {
            return "\(days) \(pluralForm(days, one: "день", few: "дня", many: "дней"))"
        }

        return "\(days) \(days == 1 ? "day" : "days")"
    }

    static func priorityMetadata(_ priority: String) -> String {
        isRussian ? "\(priority) приоритет" : "\(priority) priority"
    }

    static func repeatCustomInfo(_ weekdays: [String]) -> String {
        let joined = weekdays.joined(separator: ", ")
        return isRussian ? "Задача будет появляться: \(joined)" : "This task will appear on: \(joined)"
    }

    static func minutes(_ value: Int) -> String {
        isRussian ? "\(value) мин" : "\(value) min"
    }

    private static func pluralForm(
        _ count: Int,
        one: String,
        few: String,
        many: String
    ) -> String {
        let value = abs(count)
        let lastTwoDigits = value % 100
        let lastDigit = value % 10

        if (11...14).contains(lastTwoDigits) {
            return many
        }

        switch lastDigit {
        case 1:
            return one
        case 2...4:
            return few
        default:
            return many
        }
    }

    private static func tasksAccusativeCount(_ count: Int) -> String {
        "\(count) \(pluralForm(count, one: "задачу", few: "задачи", many: "задач"))"
    }
}
