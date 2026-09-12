import Foundation
import SwiftUI
import SwiftData

/// One credit account plus its recent rows, precomputed for the dashboard.
struct AccountSummary: Identifiable {
    let id: UUID
    let account: CreditAccount
    let purchases: [CardTransaction]
    let payments: [CardTransaction]
}

/// ViewModel for the dashboard — the flagship screen showing every credit
/// account with recent purchases and payments.
@MainActor
@Observable
final class DashboardViewModel {
    var accounts: [CreditAccount] = []
    var accountSummaries: [AccountSummary] = []
    var transactions: [CardTransaction] = []
    var recentActivity: [CardTransaction] = []
    var bills: [Bill] = []
    var billPayments: [BillPayment] = []
    var income: [IncomeEntry] = []
    var today = Date()

    var navigationPath = NavigationPath()
    var showingAddAccount = false
    var editingAccount: CreditAccount?
    var showingAddTransaction = false
    var editingTransaction: CardTransaction?
    var preferredAccountID: UUID?
    var viewingAccountID: UUID?
    var showOnboarding = false

    init() {
        let defaults = UserDefaults.standard
        showOnboarding = !defaults.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)

        // Dev-only launch shortcuts (zero effect on normal launches):
        //   -skipOnboarding  -> mark setup complete so QA lands on the dashboard
        //   -previewBills    -> open the Bills calendar immediately
        //   -previewAccount  -> open the first card's full history immediately
        if CommandLine.arguments.contains("-skipOnboarding") {
            defaults.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
            showOnboarding = false
        }
        if CommandLine.arguments.contains("-previewBills") {
            navigationPath.append("bills")
        }
        if CommandLine.arguments.contains("-previewAccount") {
            navigationPath.append("account")
        }
    }

    /// Called from the onboarding screen: seeds the demo household, marks
    /// setup complete, and refreshes every section of the dashboard.
    func completeSetup(context: ModelContext) {
        FinanceSeeder.shared.seedIfNeeded(context: context)
        PermissionManager.shared.completeOnboarding()
        showOnboarding = false
        refresh(context: context)
    }

    // MARK: - Refresh

    func refresh(context: ModelContext) {
        FinanceSeeder.shared.seedIfNeeded(context: context)
        today = Date()
        do {
            accounts = try context.fetch(FetchDescriptor<CreditAccount>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch accounts: \(error)")
        }
        do {
            transactions = try context.fetch(FetchDescriptor<CardTransaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
        do {
            bills = try context.fetch(FetchDescriptor<Bill>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch bills: \(error)")
        }
        do {
            billPayments = try context.fetch(FetchDescriptor<BillPayment>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch bill payments: \(error)")
        }
        do {
            income = try context.fetch(FetchDescriptor<IncomeEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        } catch {
            print("Failed to fetch income: \(error)")
        }
        rebuildEntries()
    }

    private func rebuildEntries() {
        var summaries: [AccountSummary] = []
        for account in accounts {
            let purchases = firstN(transactions.filter { $0.accountID == account.id && $0.isPurchase }, 3)
            let payments = firstN(transactions.filter { $0.accountID == account.id && $0.isPayment }, 2)
            summaries.append(AccountSummary(id: UUID(), account: account, purchases: purchases, payments: payments))
        }
        accountSummaries = summaries
        recentActivity = firstN(transactions, 8)
    }

    /// Array.prefix returns an ArraySlice; materialize to a plain array.
    private func firstN(_ txns: [CardTransaction], _ count: Int) -> [CardTransaction] {
        var result: [CardTransaction] = []
        let end = min(txns.count, count)
        for i in 0..<end {
            result.append(txns[i])
        }
        return result
    }

    // MARK: - Summary computation

    var monthSpend: Double {
        transactions.filter { $0.isPurchase && $0.date.sameMonth(as: today) }.reduce(0) { $0 + (-$1.amount) }
    }

    var monthIncomeValue: Double {
        income.filter { $0.date.sameMonth(as: today) }.reduce(0) { $0 + $1.amount }
    }

    var netThisMonth: Double {
        monthIncomeValue - monthSpend
    }

    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var totalLimit: Double {
        accounts.reduce(0) { $0 + $1.creditLimit }
    }

    var overallUtilization: Double {
        guard totalLimit > 0 else { return 0 }
        return totalBalance / totalLimit * 100.0
    }

    var dueBills: [DueBill] {
        dueBillsInMonth(bills: bills, payments: billPayments, month: today)
    }

    var unpaidDueCount: Int {
        dueBills.filter { !$0.isPaid }.count
    }

    var unpaidDueAmount: Double {
        dueBills.filter { !$0.isPaid }.reduce(0) { $0 + $1.bill.amount }
    }

    // MARK: - Navigation

    func openSettings() {
        navigationPath.append("settings")
    }

    func openBills() {
        navigationPath.append("bills")
    }

    func openIncome() {
        navigationPath.append("income")
    }

    func openBudgets() {
        navigationPath.append("budgets")
    }

    /// Entry point when a bill reminder notification fires: take the user
    /// straight to the Bills screen.
    func openBillsFromReminder(billIDString: String?) {
        openBills()
    }

    // MARK: - Sheet state

    func beginAddAccount() {
        editingAccount = nil
        showingAddAccount = true
    }

    func beginEditAccount(_ account: CreditAccount) {
        editingAccount = account
    }

    /// Tap a card on the dashboard -> its full history page.
    func openAccountDetail(_ account: CreditAccount) {
        viewingAccountID = account.id
        navigationPath.append("account")
    }

    func beginAddTransaction(for account: CreditAccount) {
        preferredAccountID = account.id
        editingTransaction = nil
        showingAddTransaction = true
    }

    func beginAddTransactionGeneric() {
        preferredAccountID = accounts.first?.id
        editingTransaction = nil
        showingAddTransaction = true
    }

    func beginEditTransaction(_ tx: CardTransaction) {
        editingTransaction = tx
    }

    // MARK: - Persistence

    func saveAccount(_ account: CreditAccount, context: ModelContext) {
        if !accounts.contains(where: { $0.id == account.id }) {
            context.insert(account)
        }
        try? context.save()
        refresh(context: context)
    }

    func deleteAccount(_ account: CreditAccount, context: ModelContext) {
        for tx in transactions.filter { $0.accountID == account.id } {
            context.delete(tx)
        }
        context.delete(account)
        try? context.save()
        refresh(context: context)
    }

    func saveTransaction(_ tx: CardTransaction, context: ModelContext) {
        let isNew = !transactions.contains(where: { $0.id == tx.id })
        if isNew {
            context.insert(tx)
            if let account = accounts.first { $0.id == tx.accountID } {
                account.balance = max(account.balance + tx.amount, 0)
            }
        }
        try? context.save()
        refresh(context: context)
    }

    func deleteTransaction(_ tx: CardTransaction, context: ModelContext) {
        if let account = accounts.first { $0.id == tx.accountID } {
            account.balance = max(account.balance - tx.amount, 0)
        }
        context.delete(tx)
        try? context.save()
        refresh(context: context)
    }
}