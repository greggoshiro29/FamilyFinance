import Foundation
import UserNotifications

/// Handles bill-reminder notifications: presents them and routes the user to
/// the Bills screen when a reminder actually fires.
///
/// Note: NOT @MainActor — UNUserNotificationCenter delivers these delegate
/// callbacks on arbitrary background threads, so we hop to the main actor
/// before invoking `onBillReminder` (which touches the UI/model).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Called by the app when a bill reminder fires. Receives the bill's
    /// UUID string (from userInfo) so the view layer can scroll to it.
    var onBillReminder: ((String?) -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let billID = notification.request.content.userInfo["billID"] as? String
        invokeOnBillReminder(billID)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // User tapped the notification (from background/terminated state):
        // route straight into the Bills screen.
        let billID = response.notification.request.content.userInfo["billID"] as? String
        invokeOnBillReminder(billID)
        completionHandler()
    }

    /// Hop to the main actor before firing the callback, since the delegate
    /// methods are called off the main thread.
    private func invokeOnBillReminder(_ billID: String?) {
        let callback = onBillReminder
        DispatchQueue.main.async {
            callback?(billID)
        }
    }
}