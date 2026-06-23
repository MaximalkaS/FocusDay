import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var userName: String
    @Published var selectedGoal: FocusGoal = .work
    @Published var morningReminderTime: Date
    @Published var eveningReminderTime: Date

    init(userName: String = "") {
        self.userName = userName
        morningReminderTime = Calendar.current.date(
            bySettingHour: 8,
            minute: 30,
            second: 0,
            of: Date()
        ) ?? Date()
        eveningReminderTime = Calendar.current.date(
            bySettingHour: 20,
            minute: 30,
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

        await NotificationService.shared.scheduleDailyNotifications(
            morningTime: morningReminderTime,
            eveningTime: eveningReminderTime
        )
    }
}
