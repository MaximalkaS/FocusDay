import Foundation

enum FocusDayWidgetStore {
    static let appGroupIdentifier = "group.com.maximka.focusday.mvp"

    private static let mainTaskTitleKey = "focusDay.mainTaskTitle"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func saveMainTaskTitle(_ title: String?) {
        if let title, title.isEmpty == false {
            defaults.set(title, forKey: mainTaskTitleKey)
        } else {
            defaults.removeObject(forKey: mainTaskTitleKey)
        }
    }

    static func readMainTaskTitle() -> String? {
        defaults.string(forKey: mainTaskTitleKey)
    }
}
