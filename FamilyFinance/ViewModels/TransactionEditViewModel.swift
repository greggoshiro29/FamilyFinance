import Foundation
import SwiftUI

/// ViewModel for the Add/Edit transaction sheet (purchase or payment).
@MainActor
@Observable
final class TransactionEditViewModel {
    var transaction: CardTransaction
    var isEditing: Bool

    var accounts: [CreditAccount]
    var selectedAccountID: UUID
    var kind: TransactionKind
    var merchant: String
    var amountText: String
    var category: ExpenseCategory
    var day: Int
    var month: Int
    var year: Int

    init(transaction: CardTransaction? = nil, accounts: [CreditAccount], preferredAccountID: UUID? = nil) {
        self.accounts = accounts
        if let transaction = transaction {
            self.transaction = transaction
            self.isEditing = true
            self.selectedAccountID = transaction.accountID
            self.kind = transaction.kind
            self.merchant = transaction.merchant
            self.amountText = String(format: "%.2f", abs(transaction.amount))
            self.category = transaction.category
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: transaction.date)
            self.day = comps.day
            self.month = comps.month
            self.year = comps.year
        } else {
            let fallback = preferredAccountID ?? accounts.first?.id ?? UUID()
            self.transaction = CardTransaction(accountID: fallback)
            self.isEditing = false
            self.selectedAccountID = fallback
            self.kind = .purchase
            self.merchant = ""
            self.amountText = "0.00"
            self.category = .groceries
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            self.day = comps.day
            self.month = comps.month
            self.year = comps.year
        }
    }

    var selectedAccount: CreditAccount {
        accounts.first { $0.id == selectedAccountID } ?? CreditAccount()
    }

    var categoryOptions: [ExpenseCategory] {
        ExpenseCategory.allCases
    }

    var days: [Int] {
        Array(1...31)
    }

    var months: [Int] {
        Array(1...12)
    }

    var years: [Int] {
        let thisYear = Calendar.current.component(.year, from: Date())
        Array(thisYear - 1...thisYear + 1)
    }

    func buildTransaction() -> CardTransaction? {
        guard let amount = try? Double(amountText) else { return nil }
        guard amount > 0 else { return nil }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 14
        comps.minute = 0
        guard let date = Calendar.current.date(from: comps) else { return nil }

        transaction.accountID = selectedAccountID
        transaction.memberName = selectedAccount.holderName
        transaction.kind = kind
        transaction.merchant = merchant != "" ? merchant : (kind == .purchase ? "Purchase" : "Payment")
        transaction.amount = kind == .purchase ? -amount : amount
        transaction.category = kind == .purchase ? category : .other
        transaction.date = date
        return transaction
    }
}