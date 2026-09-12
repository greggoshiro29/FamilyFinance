import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the Statistics / Wake-Up History screen.
@MainActor
@Observable
final class StatisticsViewModel {
    var occurrences: [AlarmOccurrence] = []
    var isLoading = false

    func loadOccurrences(context: ModelContext) {
        isLoading = true
        let descriptor = FetchDescriptor<AlarmOccurrence>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            occurrences = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch occurrences: \(error)")
        }
        isLoading = false
    }

    // MARK: - Summary Statistics

    var totalCompleted: Int {
        occurrences.filter { $0.status == .completed }.count
    }

    var totalEmergencyDismissed: Int {
        occurrences.filter { $0.status == .emergencyDismissed }.count
    }

    var totalMissed: Int {
        occurrences.filter { $0.status == .missed }.count
    }

    var averageCompletionTime: TimeInterval {
        let completed = occurrences.filter { $0.status == .completed && $0.durationSeconds > 0 }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0) { $0 + $1.durationSeconds } / Double(completed.count)
    }

    var formattedAvgTime: String {
        let minutes = Int(averageCompletionTime) / 60
        let seconds = Int(averageCompletionTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var bestAccuracy: Double {
        let completed = occurrences.filter { $0.status == .completed }
        guard !completed.isEmpty else { return 0 }
        return completed.map { $0.accuracy }.max() ?? 0
    }

    var formattedBestAccuracy: String {
        String(format: "%.1f%%", bestAccuracy)
    }

    var currentStreak: Int {
        var streak = 0
        for occ in occurrences {
            if occ.status == .completed {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var fastestTime: TimeInterval {
        let completed = occurrences.filter { $0.status == .completed && $0.durationSeconds > 0 }
        return completed.map { $0.durationSeconds }.min() ?? 0
    }

    var formattedFastestTime: String {
        let minutes = Int(fastestTime) / 60
        let seconds = Int(fastestTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var overallHitRate: String {
        let completed = occurrences.filter { $0.status == .completed }
        let totalHits = completed.reduce(0) { $0 + $1.hits }
        let totalShots = completed.reduce(0) { $0 + $1.hits + $1.misses }
        guard totalShots > 0 else { return "0%" }
        return String(format: "%.0f%%", Double(totalHits) / Double(totalShots) * 100)
    }
}