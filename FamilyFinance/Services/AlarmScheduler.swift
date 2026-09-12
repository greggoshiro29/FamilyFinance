import Foundation
import UserNotifications

/// Manages alarm scheduling using AlarmKit (iOS 26+) with UNNotification fallback.
/// Provides a unified interface regardless of which backend is available.
@MainActor
final class AlarmScheduler: ObservableObject {
    static let shared = AlarmScheduler()

    @Published var activeAlarmID: UUID?

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        // Restore active alarm state if app was terminated during challenge
        restoreActiveChallenge()
    }

    // MARK: - Public API

    /// Schedule an alarm
    func schedule(_ alarm: AlarmModel) async {
        guard alarm.isEnabled else { return }

        // First, cancel any existing schedule for this alarm
        cancel(alarm)

        if #available(iOS 26, *) {
            await scheduleWithAlarmKit(alarm)
        } else {
            scheduleWithUserNotifications(alarm)
        }
    }

    /// Cancel an alarm's schedule
    func cancel(_ alarm: AlarmModel) {
        if #available(iOS 26, *) {
            cancelAlarmKit(alarm)
        }

        // Remove the one-time identifier AND every repeat-day identifier.
        // Repeating alarms are scheduled as one notification per weekday
        // (suffix ".day1"..."day7"), so all must be removed or a toggled-off
        // repeat alarm would keep firing and edited-day leftovers would linger.
        let base = "\(Constants.alarmKitIdentifierPrefix).\(alarm.id.uuidString)"
        var identifiers = [base]
        for day in 1...7 {
            identifiers.append("\(base).day\(day)")
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel all alarms
    func cancelAll() {
        if #available(iOS 26, *) {
            cancelAllAlarmKit()
        }
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Handle an alarm firing — mark as active
    func alarmFired(_ alarm: AlarmModel) {
        activeAlarmID = alarm.id
        saveActiveChallenge(GameState(alarmID: alarm.id, requiredKills: alarm.requiredKills, difficulty: alarm.difficulty))
    }

    /// Mark the active alarm as completed/dismissed
    func dismissActiveAlarm() {
        activeAlarmID = nil
        clearActiveChallenge()
    }

    /// Check if there's an active alarm that hasn't been completed
    var hasActiveAlarm: Bool {
        activeAlarmID != nil || loadActiveChallenge() != nil
    }

    // MARK: - AlarmKit (iOS 26+)

    @available(iOS 26, *)
    private func scheduleWithAlarmKit(_ alarm: AlarmModel) async {
        // AlarmKit is available in iOS 26+.
        // The actual import of AlarmKit would be: import AlarmKit
        // For now, we use the notification fallback since AlarmKit requires
        // the actual framework to be linked.
        //
        // When AlarmKit is fully integrated:
        //   let alarmKit = AKAlarm(id: alarm.id.uuidString, ...)
        //   try await AKAlarmManager.shared.schedule(alarmKit)
        //
        // For this build, we delegate to user notifications as a documented fallback.
        scheduleWithUserNotifications(alarm)
    }

    @available(iOS 26, *)
    private func cancelAlarmKit(_ alarm: AlarmModel) {
        // Placeholder: cancel via AlarmKit when integrated
    }

    @available(iOS 26, *)
    private func cancelAllAlarmKit() {
        // Placeholder: cancel all via AlarmKit when integrated
    }

    // MARK: - User Notifications Fallback

    private func scheduleWithUserNotifications(_ alarm: AlarmModel) {
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Destroy \(alarm.requiredKills) aliens to stop the alarm."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = Constants.alarmCategoryIdentifier
        content.userInfo = [
            "alarmID": alarm.id.uuidString,
            "requiredKills": alarm.requiredKills,
            "difficulty": alarm.difficulty.rawValue,
            "sound": alarm.sound.rawValue
        ]

        let schedule = alarm.repeatSchedule

        if case .never = schedule {
            // One-time alarm
            guard let fireDate = alarm.nextFireDate() else { return }
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Constants.alarmKitIdentifierPrefix).\(alarm.id.uuidString)",
                content: content,
                trigger: trigger
            )
            notificationCenter.add(request)
        } else {
            // Repeating alarm: schedule for each active day
            // We schedule individual notifications for the next occurrence of each day
            let activeDays = schedule.activeDays

            for day in activeDays {
                // Create calendar trigger for this weekday
                var dateComponents = DateComponents()
                dateComponents.hour = alarm.hour
                dateComponents.minute = alarm.minute
                dateComponents.weekday = day

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(Constants.alarmKitIdentifierPrefix).\(alarm.id.uuidString).day\(day)",
                    content: content,
                    trigger: trigger
                )
                notificationCenter.add(request)
            }
        }
    }

    // MARK: - Active Challenge Persistence (UserDefaults)

    private func saveActiveChallenge(_ state: GameState) {
        let defaults = UserDefaults.standard
        defaults.set(state.alarmID.uuidString, forKey: Constants.UserDefaultsKeys.activeAlarmID)
        defaults.set(state.kills, forKey: Constants.UserDefaultsKeys.activeChallengeKills)
        defaults.set(state.misses, forKey: Constants.UserDefaultsKeys.activeChallengeMisses)
        defaults.set(state.startTime.timeIntervalSince1970, forKey: Constants.UserDefaultsKeys.activeChallengeStartTime)
        defaults.set(state.requiredKills, forKey: Constants.UserDefaultsKeys.activeChallengeRequiredKills)
    }

    private func loadActiveChallenge() -> GameState? {
        let defaults = UserDefaults.standard
        guard let alarmIDString = defaults.string(forKey: Constants.UserDefaultsKeys.activeAlarmID),
              let alarmID = UUID(uuidString: alarmIDString) else { return nil }

        var state = GameState(
            alarmID: alarmID,
            requiredKills: defaults.integer(forKey: Constants.UserDefaultsKeys.activeChallengeRequiredKills),
            difficulty: .normal
        )
        state.kills = defaults.integer(forKey: Constants.UserDefaultsKeys.activeChallengeKills)
        state.misses = defaults.integer(forKey: Constants.UserDefaultsKeys.activeChallengeMisses)
        state.startTime = Date(timeIntervalSince1970: defaults.double(forKey: Constants.UserDefaultsKeys.activeChallengeStartTime))
        return state
    }

    func restoreActiveChallenge() {
        if let state = loadActiveChallenge(), state.kills < state.requiredKills {
            activeAlarmID = state.alarmID
        } else {
            clearActiveChallenge()
        }
    }

    private func clearActiveChallenge() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.activeAlarmID)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.activeChallengeKills)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.activeChallengeMisses)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.activeChallengeStartTime)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.activeChallengeRequiredKills)
    }

    // MARK: - Notification Delegate Registration

    func registerNotificationCategories() {
        // Category for alarm notifications
        let category = UNNotificationCategory(
            identifier: Constants.alarmCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])
    }
}