import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let morningReminderIdentifier = "focusDay.morningReminder"
    private let eveningReminderIdentifier = "focusDay.eveningReminder"

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleDailyNotifications(morningTime: Date, eveningTime: Date) async {
        let isAuthorized = await requestAuthorization()
        guard isAuthorized else { return }

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [morningReminderIdentifier, eveningReminderIdentifier]
        )

        scheduleNotification(
            identifier: morningReminderIdentifier,
            body: LocalizedStrings.morningNotificationBody,
            date: morningTime
        )

        scheduleNotification(
            identifier: eveningReminderIdentifier,
            body: LocalizedStrings.eveningNotificationBody,
            date: eveningTime
        )
    }

    private func scheduleNotification(identifier: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = LocalizedStrings.appName
        content.body = body
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request)
    }
}
