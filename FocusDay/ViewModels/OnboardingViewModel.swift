import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var userName: String
    @Published var selectedGoal: FocusGoal = .work
    @Published var morningReminderTime: Date
    @Published var eveningReminderTime: Date
    @Published var areNotificationsEnabled: Bool = true

    init(userName: String = "") {
        self.userName = userName
        morningReminderTime = Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
        eveningReminderTime = Calendar.current.date(
            bySettingHour: 20,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    var canComplete: Bool {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func completeOnboarding() async {
        let defaults = UserDefaults.standard
        defaults.set(
            userName.trimmingCharacters(in: .whitespacesAndNewlines),
            forKey: UserDefaultsKeys.userName
        )
        defaults.set(selectedGoal.rawValue, forKey: UserDefaultsKeys.selectedGoal)
        defaults.set(morningReminderTime, forKey: UserDefaultsKeys.morningReminderTime)
        defaults.set(eveningReminderTime, forKey: UserDefaultsKeys.eveningReminderTime)
        defaults.set(areNotificationsEnabled, forKey: UserDefaultsKeys.areNotificationsEnabled)

        if areNotificationsEnabled {
            await NotificationService.shared.scheduleDailyNotifications(
                morningTime: morningReminderTime,
                eveningTime: eveningReminderTime
            )
        } else {
            NotificationService.shared.cancelDailyNotifications()
        }
    }
}
