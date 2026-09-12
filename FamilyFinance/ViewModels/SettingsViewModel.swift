import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the Settings screen.
@MainActor
@Observable
final class SettingsViewModel {
    var householdName: String {
        didSet { UserDefaults.standard.set(householdName, forKey: Constants.UserDefaultsKeys.householdName) }
    }
    var currencySymbol: String {
        didSet { UserDefaults.standard.set(currencySymbol, forKey: Constants.UserDefaultsKeys.currencySymbol) }
    }
    var remindersEnabled: Bool {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled) }
    }
    var defaultReminderDays: Int {
        didSet { UserDefaults.standard.set(defaultReminderDays, forKey: Constants.UserDefaultsKeys.defaultReminderDays) }
    }

    var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let permissionManager = PermissionManager.shared

    var showingAddMember = false
    var editingMember: FamilyMember?
    var members: [FamilyMember] = []

    init() {
        let defaults = UserDefaults.standard

        householdName = defaults.string(forKey: Constants.UserDefaultsKeys.householdName) ?? "Our Family"
        currencySymbol = defaults.string(forKey: Constants.UserDefaultsKeys.currencySymbol) ?? Constants.currencySymbol
        remindersEnabled = defaults.bool(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled)
        defaultReminderDays = defaults.integer(forKey: Constants.UserDefaultsKeys.defaultReminderDays) > 0
            ? defaults.integer(forKey: Constants.UserDefaultsKeys.defaultReminderDays)
            : Constants.defaultReminderDaysBefore

        notificationStatus = permissionManager.notificationStatus
    }

    func loadMembers(context: ModelContext) {
        do {
            members = try context.fetch(FetchDescriptor<FamilyMember>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch members: \\(error)")
        }
    }

    var currencyOptions: [String] {
        Constants.currencySymbols
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

    // MARK: - Members

    func beginAddMember() {
        editingMember = nil
        showingAddMember = true
    }

    func beginEditMember(_ member: FamilyMember) {
        editingMember = member
    }

    func saveMember(_ member: FamilyMember, context: ModelContext) {
        if !members.contains(where: { $0.id == member.id }) {
            context.insert(member)
        }
        try? context.save()
        loadMembers(context: context)
    }

    func deleteMember(_ member: FamilyMember, context: ModelContext) {
        context.delete(member)
        try? context.save()
        loadMembers(context: context)
    }

    // MARK: - Demo data

    /// Wipes every finance record; the app reseeds a fresh household on next
    /// launch (used for demos and testing).
    func resetDemoData(context: ModelContext) {
        do {
            let accounts = try context.fetch(FetchDescriptor<CreditAccount>())
            for item in accounts { context.delete(item) }
        } catch {}
        do {
            let items = try context.fetch(FetchDescriptor<CardTransaction>())
            for item in items { context.delete(item) }
        } catch {}
        do {
            let items = try context.fetch(FetchDescriptor<Bill>())
            for item in items { context.delete(item) }
        } catch {}
        do {
            let items = try context.fetch(FetchDescriptor<BillPayment>())
            for item in items { context.delete(item) }
        } catch {}
        do {
            let items = try context.fetch(FetchDescriptor<IncomeEntry>())
            for item in items { context.delete(item) }
        } catch {}
        do {
            let items = try context.fetch(FetchDescriptor<BudgetCategory>())
            for item in items { context.delete(item) }
        } catch {}
        do {
            let items = try context.fetch(FetchDescriptor<FamilyMember>())
            for item in items { context.delete(item) }
        } catch {}
        try? context.save()
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.hasSeededDemoData)
        print("FamilyFinance: demo data reset — relaunch to reseed")
    }
}