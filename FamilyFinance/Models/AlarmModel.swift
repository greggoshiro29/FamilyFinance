import Foundation
import SwiftData

@Model
final class AlarmModel {
    var id: UUID
    var time: Date // Stored as hour/minute; date portion is arbitrary
    var label: String
    var repeatScheduleRaw: String // Codable JSON for RepeatSchedule
    var soundRaw: String // AlarmSound rawValue
    var vibrationEnabled: Bool
    var difficultyRaw: String // Difficulty rawValue
    var requiredKills: Int
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var occurrences: [AlarmOccurrence] = []

    init(
        id: UUID = UUID(),
        time: Date = Date(),
        label: String = "Alarm",
        repeatSchedule: RepeatSchedule = .never,
        sound: AlarmSound = .spaceSiren,
        vibrationEnabled: Bool = true,
        difficulty: Difficulty = .normal,
        requiredKills: Int = Constants.defaultRequiredKills,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.repeatScheduleRaw = (try? JSONEncoder().encode(repeatSchedule)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        self.soundRaw = sound.rawValue
        self.vibrationEnabled = vibrationEnabled
        self.difficultyRaw = difficulty.rawValue
        self.requiredKills = requiredKills
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var repeatSchedule: RepeatSchedule {
        get {
            guard let data = repeatScheduleRaw.data(using: .utf8),
                  let schedule = try? JSONDecoder().decode(RepeatSchedule.self, from: data) else {
                return .never
            }
            return schedule
        }
        set {
            repeatScheduleRaw = (try? JSONEncoder().encode(newValue)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        }
    }

    var sound: AlarmSound {
        get { AlarmSound(rawValue: soundRaw) ?? .spaceSiren }
        set { soundRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .normal }
        set { difficultyRaw = newValue.rawValue }
    }

    var hour: Int {
        Calendar.current.component(.hour, from: time)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: time)
    }

    var formattedTime: String {
        time.formattedTime12h
    }

    /// Compute the next fire date from now
    func nextFireDate() -> Date? {
        let schedule = repeatSchedule
        if case .never = schedule {
            // One-time alarm: if time is in the future today, use today; otherwise return nil (already fired)
            let now = Date()
            let calendar = Calendar.current
            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            guard let candidate = calendar.date(from: comps), candidate > now else { return nil }
            return candidate
        }
        return Date().nextOccurrence(hour: hour, minute: minute, activeDays: schedule.activeDays)
    }
}