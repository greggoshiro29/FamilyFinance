import Foundation

enum Constants {
    /// Default number of aliens required to dismiss alarm
    static let defaultRequiredKills: Int = 10

    /// Shot cooldown in seconds
    static let shotCooldown: TimeInterval = 0.4

    /// Alien spawn interval range in seconds
    static let alienSpawnIntervalRange: ClosedRange<TimeInterval> = 1.5...2.5

    /// Maximum game pause before resetting current alien (seconds)
    static let maxPauseDuration: TimeInterval = 30.0

    /// AlarmKit identifier prefix
    static let alarmKitIdentifierPrefix = "com.alienalarm"

    /// Notification category identifier
    static let alarmCategoryIdentifier = "ALARM_CATEGORY"

    /// UserDefaults keys
    struct UserDefaultsKeys {
        static let activeAlarmID = "activeAlarmID"
        static let activeChallengeKills = "activeChallengeKills"
        static let activeChallengeMisses = "activeChallengeMisses"
        static let activeChallengeStartTime = "activeChallengeStartTime"
        static let activeChallengeRequiredKills = "activeChallengeRequiredKills"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let emergencyExitEnabled = "emergencyExitEnabled"
        static let defaultDifficulty = "defaultDifficulty"
        static let defaultAlarmSound = "defaultAlarmSound"
        static let defaultVibration = "defaultVibration"
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"

    /// Multiplier for alien movement speed
    var speedMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .normal: return 1.35
        case .hard: return 2.0
        }
    }
}

enum AlarmSound: String, Codable, CaseIterable {
    case spaceSiren = "Space Siren"
    case reactorAlert = "Reactor Alert"
    case commandAlarm = "Command Alarm"
    case alienInvasion = "Alien Invasion"
    case emergencyPulse = "Emergency Pulse"
}

enum RepeatSchedule: Codable, Hashable, Equatable {
    case never
    case everyDay
    case weekdays
    case weekends
    case custom(Set<Int>) // 1=Sun ... 7=Sat

    var displayName: String {
        switch self {
        case .never: return "Never"
        case .everyDay: return "Every Day"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom"
        }
    }

    var activeDays: Set<Int> {
        switch self {
        case .never: return []
        case .everyDay: return Set(1...7)
        case .weekdays: return Set(2...6)
        case .weekends: return Set([1, 7])
        case .custom(let days): return days
        }
    }
}

enum CompletionStatus: String, Codable {
    case completed = "Completed"
    case emergencyDismissed = "Emergency Dismissed"
    case missed = "Missed"
}