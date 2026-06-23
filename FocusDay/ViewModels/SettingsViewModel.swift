import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var userName: String
    @Published var selectedGoal: FocusGoal
    @Published var morningReminderTime: Date
    @Published var eveningReminderTime: Date
    @Published private(set) var isSaving = false

    init(userName: String? = nil) {
        let defaults = UserDefaults.standard
        self.userName = userName ?? defaults.string(forKey: UserDefaultsKeys.userName) ?? ""
        let savedGoalRawValue = defaults.string(forKey: UserDefaultsKeys.selectedGoal)
        selectedGoal = savedGoalRawValue.flatMap(FocusGoal.init(rawValue:)) ?? .work

        morningReminderTime = defaults.object(forKey: UserDefaultsKeys.morningReminderTime) as? Date
            ?? Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())
            ?? Date()
        eveningReminderTime = defaults.object(forKey: UserDefaultsKeys.eveningReminderTime) as? Date
            ?? Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date())
            ?? Date()
    }

    func saveSettings() async -> Bool {
        guard isSaving == false else { return false }
        isSaving = true
        defer { isSaving = false }

        let defaults = UserDefaults.standard
        defaults.set(
            userName.trimmingCharacters(in: .whitespacesAndNewlines),
            forKey: UserDefaultsKeys.userName
        )
        defaults.set(selectedGoal.rawValue, forKey: UserDefaultsKeys.selectedGoal)
        defaults.set(morningReminderTime, forKey: UserDefaultsKeys.morningReminderTime)
        defaults.set(eveningReminderTime, forKey: UserDefaultsKeys.eveningReminderTime)

        await NotificationService.shared.scheduleDailyNotifications(
            morningTime: morningReminderTime,
            eveningTime: eveningReminderTime
        )

        return true
    }
}

enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "focusDay.hasCompletedOnboarding"
    static let userName = "focusDay.userName"
    static let selectedGoal = "focusDay.selectedGoal"
    static let morningReminderTime = "focusDay.morningReminderTime"
    static let eveningReminderTime = "focusDay.eveningReminderTime"
}
