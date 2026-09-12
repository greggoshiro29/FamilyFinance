import Foundation
import UserNotifications

/// Schedules bill reminders through the User Notifications service and
/// provides a demo reminder used by Settings ("Send Test Reminder").
@MainActor
final class BillReminderScheduler: ObservableObject {
    static let shared = BillReminderScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Public API

    /// Re-schedules reminders for every active bill. Safe to call on every
    /// dashboard refresh: cancelAll then re-add is cheap and idempotent.
    func refreshAll(_ bills: [Bill]) {
        if !remindersEnabled {
            cancelAll()
            return
        }
        cancelAll()
        for bill in bills {
            schedule(bill)
        }
    }

    /// Schedule a single reminder for the bill's next occurrence.
    func schedule(_ bill: Bill) {
        guard bill.isActive else { return }
        let now = Date()
        guard let due = bill.occurrence(on: now) else { return }
        let calendar = Calendar.current
        let fireDate = calendar.date(byAdding: .day, value: -bill.reminderDaysBefore, to: due) ?? due
        guard fireDate > now else { return } // Skip windows already past

        let content = UNMutableNotificationContent()
        content.title = "Bill due: \\(bill.name)"
        content.body = "\\(bill.amount.currencyString) due on \\(due.shortDateLabel)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Constants.reminderCategoryIdentifier
        content.userInfo = ["billID": bill.id.uuidString]

        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\\(Constants.reminderIdentifierPrefix).\\(bill.id.uuidString)",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(request)
    }

    /// Remove the reminder for one bill.
    func cancel(_ bill: Bill) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["\\(Constants.reminderIdentifierPrefix).\\(bill.id.uuidString)"]
        )
    }

    /// Remove every pending reminder (used when toggling reminders off).
    func cancelAll() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Schedules a demo reminder ~25 seconds out so the user can see how a
    /// bill reminder banner behaves without waiting for a real due date.
    func scheduleDemoReminder(_ bill: Bill) {
        let calendar = Calendar.current
        let fireDate = calendar.date(byAdding: .second, value: 25, to: Date()) ?? Date()
        let dueLabel = bill.occurrence(on: Date())?.shortDateLabel ?? ""
        let content = UNMutableNotificationContent()
        content.title = "Demo: \\(bill.name) is due soon"
        content.body = "\\(bill.amount.currencyString) due on \\(dueLabel) — tap to open Bills"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Constants.reminderCategoryIdentifier
        content.userInfo = ["billID": bill.id.uuidString]

        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\\(Constants.reminderIdentifierPrefix).demo",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(request)
    }

    var remindersEnabled: Bool {
        UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled)
    }

    // MARK: - Category Registration

    func registerNotificationCategories() {
        let category = UNNotificationCategory(
            identifier: Constants.reminderCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])
    }
}