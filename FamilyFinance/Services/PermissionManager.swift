import Foundation
import UserNotifications
import UIKit

/// Manages notification and alarm permissions.
/// Handles onboarding flow for requesting permissions.
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        }
    }

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        Task {
            await refreshStatus()
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    /// Request notification permission with alarm-critical options
    func requestNotificationPermission() async -> Bool {
        let baseOptions: UNAuthorizationOptions = [.alert, .sound, .badge]

        do {
            // Critical alerts only work with Apple's critical-alert entitlement,
            // which is granted on a per-app basis and is rarely available for
            // App Store apps. Requesting .criticalAlert without it makes the
            // WHOLE request throw, so the user would never see even the basic
            // prompt. Attempt it first, and fall back to standard options.
            var options = baseOptions
            options.insert(.criticalAlert)
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await refreshStatus()
            return granted
        } catch {
            // Critical alert unavailable (no entitlement) — retry without it so
            // regular alert/sound/badge permissions still work.
            print("PermissionManager: critical-alert request failed (\(error)); retrying standard options")
            return await requestStandardPermission(baseOptions)
        }
    }

    private func requestStandardPermission(_ options: UNAuthorizationOptions) async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await refreshStatus()
            return granted
        } catch {
            print("PermissionManager: Failed to request permission: \(error)")
            return false
        }
    }

    /// Check if AlarmKit is available (iOS 26+)
    var isAlarmKitAvailable: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }

    /// Mark onboarding as complete
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Open system Settings app to let user fix permissions
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}