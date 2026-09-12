import Foundation
import SwiftData

@Model
final class AlarmOccurrence {
    var id: UUID
    var alarmID: UUID
    var scheduledTime: Date
    var actualCompletionTime: Date?
    var statusRaw: String // CompletionStatus rawValue
    var hits: Int
    var misses: Int
    var durationSeconds: TimeInterval
    var createdAt: Date

    init(
        id: UUID = UUID(),
        alarmID: UUID,
        scheduledTime: Date,
        status: CompletionStatus = .missed,
        hits: Int = 0,
        misses: Int = 0,
        durationSeconds: TimeInterval = 0
    ) {
        self.id = id
        self.alarmID = alarmID
        self.scheduledTime = scheduledTime
        self.statusRaw = status.rawValue
        self.hits = hits
        self.misses = misses
        self.durationSeconds = durationSeconds
        self.createdAt = Date()
    }

    var status: CompletionStatus {
        get { CompletionStatus(rawValue: statusRaw) ?? .missed }
        set { statusRaw = newValue.rawValue }
    }

    var accuracy: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total) * 100.0
    }

    var formattedDuration: String {
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}