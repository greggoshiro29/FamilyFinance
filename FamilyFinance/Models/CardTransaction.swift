import Foundation
import SwiftData

/// A single credit-card line item: a purchase (negative amount) or a
/// payment (positive amount). Sign convention lets the account balance be
/// `balance = seeded balance + sum(amounts)` for new entries.
@Model
final class CardTransaction {
    var id: UUID
    var accountID: UUID
    var memberName: String
    var kindRaw: String // TransactionKind rawValue
    var merchant: String
    var amount: Double
    var categoryRaw: String // ExpenseCategory rawValue (purchases)
    var date: Date
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        accountID: UUID,
        memberName: String = "",
        kind: TransactionKind = .purchase,
        merchant: String = "Merchant",
        amount: Double = 0,
        category: ExpenseCategory = .other,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.accountID = accountID
        self.memberName = memberName
        self.kindRaw = kind.rawValue
        self.merchant = merchant
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.date = date
        self.note = note
        self.createdAt = Date()
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .purchase }
        set { kindRaw = newValue.rawValue }
    }

    var category: ExpenseCategory {
        get {
            if categoryRaw == "" { return .other }
            return ExpenseCategory(rawValue: categoryRaw) ?? .other
        }
        set { categoryRaw = newValue.rawValue }
    }

    var isPurchase: Bool {
        kind == .purchase
    }

    var isPayment: Bool {
        kind == .payment
    }
}