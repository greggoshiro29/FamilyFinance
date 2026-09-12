import Foundation
import SwiftUI

/// ViewModel for adding and editing alarms.
@MainActor
@Observable
final class AlarmEditViewModel {
    var alarm: AlarmModel
    var isEditing: Bool

    // Form state
    var selectedHour: Int
    var selectedMinute: Int
    var isPM: Bool
    var label: String
    var repeatSchedule: RepeatSchedule
    var customDays: Set<Int>
    var selectedSound: AlarmSound
    var vibrationEnabled: Bool
    var difficulty: Difficulty
    var requiredKills: Int

    init(alarm: AlarmModel? = nil) {
        if let alarm = alarm {
            self.alarm = alarm
            self.isEditing = true
            self.selectedHour = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12
            self.isPM = alarm.hour >= 12
            self.selectedMinute = alarm.minute
            self.label = alarm.label
            self.repeatSchedule = alarm.repeatSchedule
            if case .custom(let days) = alarm.repeatSchedule {
                self.customDays = days
            } else {
                self.customDays = Set(2...6)
            }
            self.selectedSound = alarm.sound
            self.vibrationEnabled = alarm.vibrationEnabled
            self.difficulty = alarm.difficulty
            self.requiredKills = alarm.requiredKills
        } else {
            let now = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: now)
            self.alarm = AlarmModel()
            self.isEditing = false
            self.selectedHour = hour % 12 == 0 ? 12 : hour % 12
            self.isPM = hour >= 12
            self.selectedMinute = (calendar.component(.minute, from: now) + 1) % 60
            self.label = "Alarm"
            self.repeatSchedule = .never
            self.customDays = Set(2...6)
            self.selectedSound = .spaceSiren
            self.vibrationEnabled = true
            self.difficulty = .normal
            self.requiredKills = Constants.defaultRequiredKills
        }
    }

    var hourIn24: Int {
        let h = selectedHour % 12
        return isPM ? (h + 12) : h
    }

    var formattedTime: String {
        let h = selectedHour == 0 ? 12 : selectedHour
        let ampm = isPM ? "PM" : "AM"
        return String(format: "%d:%02d %@", h, selectedMinute, ampm)
    }

    func buildAlarm() -> AlarmModel {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hourIn24
        components.minute = selectedMinute
        let time = calendar.date(from: components) ?? Date()

        let finalRepeat: RepeatSchedule
        switch repeatSchedule {
        case .custom:
            finalRepeat = .custom(customDays)
        default:
            finalRepeat = repeatSchedule
        }

        alarm.time = time
        alarm.label = label
        alarm.repeatSchedule = finalRepeat
        alarm.sound = selectedSound
        alarm.vibrationEnabled = vibrationEnabled
        alarm.difficulty = difficulty
        alarm.requiredKills = requiredKills
        alarm.updatedAt = Date()

        return alarm
    }

    func previewSound() {
        AudioManager.shared.previewAlarm(sound: selectedSound)
    }

    var repeatOptions: [RepeatSchedule] {
        [.never, .everyDay, .weekdays, .weekends, .custom(Set(2...6))]
    }

    var difficultyOptions: [Difficulty] {
        Difficulty.allCases
    }

    var soundOptions: [AlarmSound] {
        AlarmSound.allCases
    }

    var hours: [Int] {
        Array(1...12)
    }

    var minutes: [Int] {
        Array(0...59)
    }
}