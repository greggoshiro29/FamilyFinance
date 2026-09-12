import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the Alarm List screen.
@MainActor
@Observable
final class AlarmListViewModel {
    var alarms: [AlarmModel] = []
    var currentTime: Date = Date()
    var navigationPath = NavigationPath()
    var showingAddAlarm = false
    var editingAlarm: AlarmModel?
    var activeAlarm: AlarmModel?
    var showActiveAlarm = false
    var showOnboarding = false

    private var timeTimer: Timer?

    init() {
        startClock()
        checkOnboarding()
    }

    private func startClock() {
        currentTime = Date()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = Date()
            }
        }
    }

    private func checkOnboarding() {
        if !PermissionManager.shared.hasCompletedOnboarding {
            showOnboarding = true
        }
    }

    func loadAlarms(context: ModelContext) {
        let descriptor = FetchDescriptor<AlarmModel>(sortBy: [SortDescriptor(\.time)])
        do {
            alarms = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch alarms: \(error)")
        }
    }

    func toggleAlarm(_ alarm: AlarmModel, context: ModelContext) {
        alarm.isEnabled.toggle()
        alarm.updatedAt = Date()
        try? context.save()

        Task {
            if alarm.isEnabled {
                await AlarmScheduler.shared.schedule(alarm)
            } else {
                AlarmScheduler.shared.cancel(alarm)
            }
        }
    }

    func deleteAlarm(_ alarm: AlarmModel, context: ModelContext) {
        AlarmScheduler.shared.cancel(alarm)
        context.delete(alarm)
        try? context.save()
        loadAlarms(context: context)
    }

    func saveAlarm(_ alarm: AlarmModel, context: ModelContext) {
        if !alarms.contains(where: { $0.id == alarm.id }) {
            context.insert(alarm)
        }
        alarm.updatedAt = Date()
        try? context.save()

        Task {
            if alarm.isEnabled {
                await AlarmScheduler.shared.schedule(alarm)
            }
        }

        loadAlarms(context: context)
    }

    func startChallenge(for alarm: AlarmModel) {
        activeAlarm = alarm
        showActiveAlarm = true
        AlarmScheduler.shared.alarmFired(alarm)
    }

    /// Handle an alarm notification firing by looking up the alarm and
    /// launching its wake-up challenge (ActiveAlarmView -> GameView).
    func handleAlarmFired(uuid: UUID, context: ModelContext?) {
        let target: AlarmModel?
        if let context {
            let descriptor = FetchDescriptor<AlarmModel>(
                predicate: #Predicate { $0.id == uuid }
            )
            target = try? context.fetch(descriptor).first
        } else {
            target = alarms.first { $0.id == uuid }
        }

        if let alarm = target {
            startChallenge(for: alarm)
        } else {
            // Alarm not found in store yet (edge case) — fall back.
            showActiveAlarmWithAnyAlarm(context: context)
        }
    }

    /// Fallback: surface the challenge UI with a generic alarm if the specific
    /// alarm cannot be resolved.
    func showActiveAlarmWithAnyAlarm(context: ModelContext?) {
        let target = alarms.first ?? fetchFirstAlarm(context: context)
        if let alarm = target {
            startChallenge(for: alarm)
        } else {
            // No alarms exist at all — nothing to fire, but still allow a
            // generic challenge session so the game can be tested.
            let generic = AlarmModel()
            generic.label = "Alarm"
            startChallenge(for: generic)
        }
    }

    private func fetchFirstAlarm(context: ModelContext?) -> AlarmModel? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<AlarmModel>(sortBy: [SortDescriptor(\.time)])
        return try? context.fetch(descriptor).first
    }

    func dismissActiveAlarm() {
        activeAlarm = nil
        showActiveAlarm = false
        AlarmScheduler.shared.dismissActiveAlarm()
    }

    func completeOnboarding() {
        PermissionManager.shared.completeOnboarding()
        showOnboarding = false
    }
}