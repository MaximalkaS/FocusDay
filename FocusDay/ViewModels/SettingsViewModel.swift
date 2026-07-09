import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var userName: String
    @Published var selectedGoal: FocusGoal
    @Published var morningReminderTime: Date
    @Published var eveningReminderTime: Date
    @Published var areNotificationsEnabled: Bool
    @Published private(set) var isSaving = false
    @Published private(set) var saveErrorMessage: String?
    @Published private var savedSnapshot: SettingsSnapshot

    init(
        userName: String? = nil,
        morningReminderTime: Date? = nil,
        eveningReminderTime: Date? = nil,
        areNotificationsEnabled: Bool? = nil
    ) {
        let defaults = UserDefaults.standard
        let resolvedUserName = userName ?? defaults.string(forKey: UserDefaultsKeys.userName) ?? ""
        let savedGoalRawValue = defaults.string(forKey: UserDefaultsKeys.selectedGoal)
        let resolvedGoal = savedGoalRawValue.flatMap(FocusGoal.init(rawValue:)) ?? .work

        let resolvedMorningReminderTime = morningReminderTime
            ?? defaults.object(forKey: UserDefaultsKeys.morningReminderTime) as? Date
            ?? Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())
            ?? Date()
        let resolvedEveningReminderTime = eveningReminderTime
            ?? defaults.object(forKey: UserDefaultsKeys.eveningReminderTime) as? Date
            ?? Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date())
            ?? Date()
        let resolvedNotificationsEnabled = areNotificationsEnabled
            ?? defaults.object(forKey: UserDefaultsKeys.areNotificationsEnabled) as? Bool
            ?? true

        self.userName = resolvedUserName
        selectedGoal = resolvedGoal
        self.morningReminderTime = resolvedMorningReminderTime
        self.eveningReminderTime = resolvedEveningReminderTime
        self.areNotificationsEnabled = resolvedNotificationsEnabled
        savedSnapshot = SettingsSnapshot(
            userName: resolvedUserName,
            selectedGoal: resolvedGoal,
            morningReminderTime: resolvedMorningReminderTime,
            eveningReminderTime: resolvedEveningReminderTime,
            areNotificationsEnabled: resolvedNotificationsEnabled
        )
    }

    var hasUnsavedChanges: Bool {
        currentSnapshot != savedSnapshot
    }

    func saveSettings() async -> Bool {
        guard isSaving == false else { return false }
        isSaving = true
        saveErrorMessage = nil
        defer { isSaving = false }

        let defaults = UserDefaults.standard
        defaults.set(
            userName.trimmingCharacters(in: .whitespacesAndNewlines),
            forKey: UserDefaultsKeys.userName
        )
        defaults.set(selectedGoal.rawValue, forKey: UserDefaultsKeys.selectedGoal)
        defaults.set(morningReminderTime, forKey: UserDefaultsKeys.morningReminderTime)
        defaults.set(eveningReminderTime, forKey: UserDefaultsKeys.eveningReminderTime)
        defaults.set(areNotificationsEnabled, forKey: UserDefaultsKeys.areNotificationsEnabled)

        guard areNotificationsEnabled else {
            NotificationService.shared.cancelDailyNotifications()
            savedSnapshot = currentSnapshot
            return true
        }

        let didScheduleNotifications = await NotificationService.shared.scheduleDailyNotifications(
            morningTime: morningReminderTime,
            eveningTime: eveningReminderTime
        )

        if didScheduleNotifications == false {
            saveErrorMessage = LocalizedStrings.notificationScheduleError
        }

        if didScheduleNotifications {
            savedSnapshot = currentSnapshot
        }

        return didScheduleNotifications
    }

    private var currentSnapshot: SettingsSnapshot {
        SettingsSnapshot(
            userName: userName,
            selectedGoal: selectedGoal,
            morningReminderTime: morningReminderTime,
            eveningReminderTime: eveningReminderTime,
            areNotificationsEnabled: areNotificationsEnabled
        )
    }
}

private struct SettingsSnapshot: Equatable {
    let userName: String
    let selectedGoal: FocusGoal
    let morningReminderTime: ReminderTimeSnapshot
    let eveningReminderTime: ReminderTimeSnapshot
    let areNotificationsEnabled: Bool

    init(
        userName: String,
        selectedGoal: FocusGoal,
        morningReminderTime: Date,
        eveningReminderTime: Date,
        areNotificationsEnabled: Bool
    ) {
        self.userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.selectedGoal = selectedGoal
        self.morningReminderTime = ReminderTimeSnapshot(date: morningReminderTime)
        self.eveningReminderTime = ReminderTimeSnapshot(date: eveningReminderTime)
        self.areNotificationsEnabled = areNotificationsEnabled
    }
}

private struct ReminderTimeSnapshot: Equatable {
    let hour: Int
    let minute: Int

    init(date: Date, calendar: Calendar = .current) {
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
    }
}

enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "focusDay.hasCompletedOnboarding"
    static let userName = "focusDay.userName"
    static let selectedGoal = "focusDay.selectedGoal"
    static let morningReminderTime = "focusDay.morningReminderTime"
    static let eveningReminderTime = "focusDay.eveningReminderTime"
    static let areNotificationsEnabled = "focusDay.areNotificationsEnabled"
    static let lastStreakCelebrationDay = "focusDay.lastStreakCelebrationDay"
}
