import Foundation
import SwiftUI
import SwiftData

/// One month of a card's activity, with split totals.
struct MonthGroup: Identifiable {
    let id: UUID
    let label: String
    let purchases: [CardTransaction]
    let payments: [CardTransaction]
    let purchasesTotal: Double
    let paymentsTotal: Double
}

/// ViewModel for the per-account detail / full history page.
@MainActor
@Observable
final class AccountDetailViewModel {
    var account: CreditAccount?
    var transactions: [CardTransaction] = []
    var groups: [MonthGroup] = []

    /// Loads the account (or the first available when accountID is nil) and
    /// its full transaction history, grouped newest month first.
    func refresh(context: ModelContext, accountID: UUID?) {
        do {
            let accounts = try context.fetch(FetchDescriptor<CreditAccount>(sortBy: [SortDescriptor(\.createdAt)]))
            account = if let accountID {
                accounts.first { $0.id == accountID } ?? accounts.first
            } else {
                accounts.first
            }
        } catch {
            print("Failed to fetch account: \(error)")
            account = nil
        }
        guard let account = account else {
            transactions = []
            groups = []
            return
        }
        let targetID = account.id
        do {
            transactions = try context.fetch(FetchDescriptor<CardTransaction>(
                predicate: #Predicate { $0.accountID == targetID },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            ))
        } catch {
            print("Failed to fetch transactions: \(error)")
            transactions = []
        }
        rebuildGroups()
    }

    private func rebuildGroups() {
        var list: [MonthGroup] = []
        var key = ""
        var purchases: [CardTransaction] = []
        var payments: [CardTransaction] = []
        for tx in transactions {
            if key != "" && tx.date.periodKey != key {
                let sample = purchases.first?.date ?? payments.first?.date ?? Date()
                list.append(buildGroup(key: key, label: sample.monthYearLabel, purchases: purchases, payments: payments))
                purchases = []
                payments = []
            }
            key = tx.date.periodKey
            if tx.isPurchase {
                purchases.append(tx)
            } else {
                payments.append(tx)
            }
        }
        if key != "" {
            let sample = purchases.first?.date ?? payments.first?.date ?? Date()
            list.append(buildGroup(key: key, label: sample.monthYearLabel, purchases: purchases, payments: payments))
        }
        groups = list
    }

    private func buildGroup(key: String, label: String, purchases: [CardTransaction], payments: [CardTransaction]) -> MonthGroup {
        let purchasesTotal = purchases.reduce(0) { $0 + (-$1.amount) }
        let paymentsTotal = payments.reduce(0) { $0 + $1.amount }
        return MonthGroup(id: UUID(), label: label, purchases: purchases, payments: payments, purchasesTotal: purchasesTotal, paymentsTotal: paymentsTotal)
    }
}