import Foundation
import SwiftUI

/// ViewModel for the Settings screen.
@MainActor
@Observable
final class SettingsViewModel {
    var defaultRequiredKills: Int = Constants.defaultRequiredKills {
        didSet { UserDefaults.standard.set(defaultRequiredKills, forKey: "defaultRequiredKills") }
    }
    var defaultDifficulty: Difficulty = .normal {
        didSet { UserDefaults.standard.set(defaultDifficulty.rawValue, forKey: Constants.UserDefaultsKeys.defaultDifficulty) }
    }
    var defaultAlarmSound: AlarmSound = .spaceSiren {
        didSet { UserDefaults.standard.set(defaultAlarmSound.rawValue, forKey: Constants.UserDefaultsKeys.defaultAlarmSound) }
    }
    var defaultVibration: Bool = true {
        didSet { UserDefaults.standard.set(defaultVibration, forKey: Constants.UserDefaultsKeys.defaultVibration) }
    }
    var emergencyExitEnabled: Bool = true {
        didSet { UserDefaults.standard.set(emergencyExitEnabled, forKey: Constants.UserDefaultsKeys.emergencyExitEnabled) }
    }

    var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let permissionManager = PermissionManager.shared

    init() {
        let defaults = UserDefaults.standard

        let savedKills = defaults.integer(forKey: "defaultRequiredKills")
        if savedKills > 0 {
            defaultRequiredKills = savedKills
        }

        let savedDiff = defaults.string(forKey: Constants.UserDefaultsKeys.defaultDifficulty)
        if let diff = savedDiff, let d = Difficulty(rawValue: diff) {
            defaultDifficulty = d
        }

        let savedSound = defaults.string(forKey: Constants.UserDefaultsKeys.defaultAlarmSound)
        if let s = savedSound, let sound = AlarmSound(rawValue: s) {
            defaultAlarmSound = sound
        }

        if defaults.object(forKey: Constants.UserDefaultsKeys.defaultVibration) != nil {
            defaultVibration = defaults.bool(forKey: Constants.UserDefaultsKeys.defaultVibration)
        }

        if defaults.object(forKey: Constants.UserDefaultsKeys.emergencyExitEnabled) != nil {
            emergencyExitEnabled = defaults.bool(forKey: Constants.UserDefaultsKeys.emergencyExitEnabled)
        }

        notificationStatus = permissionManager.notificationStatus
    }

    func refreshPermissionStatus() async {
        await permissionManager.refreshStatus()
        notificationStatus = permissionManager.notificationStatus
    }

    func requestPermissions() async -> Bool {
        let granted = await permissionManager.requestNotificationPermission()
        await refreshPermissionStatus()
        return granted
    }

    func openSystemSettings() {
        permissionManager.openSystemSettings()
    }

    var isAlarmKitAvailable: Bool {
        permissionManager.isAlarmKitAvailable
    }

    func testAlarm() {
        AudioManager.shared.previewAlarm(sound: defaultAlarmSound)
        HapticManager.shared.alarmActivated()
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        permissionManager.hasCompletedOnboarding = false
    }
}