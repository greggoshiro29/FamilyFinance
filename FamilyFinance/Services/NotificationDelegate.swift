import Foundation
import UserNotifications

/// Handles alarm notifications: presents them even in the foreground and
/// triggers the wake-up challenge (ActiveAlarmView -> GameView) when an
/// alarm actually fires. This is the missing bridge between a scheduled
/// local notification and the app's game flow.
///
/// Note: NOT @MainActor — UNUserNotificationCenter delivers these delegate
/// callbacks on arbitrary background threads, so we hop to the main actor
/// before invoking `onAlarmFired` (which touches the UI/model).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Called by the app when an alarm notification fires. Receives the
    /// alarm's UUID string (from userInfo) so the view layer can look up and
    /// launch the matching alarm's challenge.
    var onAlarmFired: ((String?) -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let alarmID = notification.request.content.userInfo["alarmID"] as? String
        invokeOnAlarmFired(alarmID)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // User tapped the notification (from background/terminated state):
        // route straight into the challenge for that alarm.
        let alarmID = response.notification.request.content.userInfo["alarmID"] as? String
        invokeOnAlarmFired(alarmID)
        completionHandler()
    }

    /// Hop to the main actor before firing the callback, since the delegate
    /// methods are called off the main thread.
    private func invokeOnAlarmFired(_ alarmID: String?) {
        let callback = onAlarmFired
        DispatchQueue.main.async {
            callback?(alarmID)
        }
    }
}
