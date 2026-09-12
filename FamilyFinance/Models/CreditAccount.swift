import Foundation
import SwiftData

/// A credit card account owned by a family member.
@Model
final class CreditAccount {
    var id: UUID
    var issuer: String
    var holderName: String // Denormalized family member name shown on the card
    var lastFour: String
    var balance: Double // Current balance owed (positive)
    var creditLimit: Double
    var apr: Double // Annual percentage rate, e.g. 24.99
    var statementDay: Int // Day the statement closes
    var dueDay: Int // Day the payment is due
    var colorRaw: String // AccountColor rawValue
    var isArchived: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        issuer: String = "Credit Card",
        holderName: String = "",
        lastFour: String = "0000",
        balance: Double = 0,
        creditLimit: Double = 1000,
        apr: Double = 24.99,
        statementDay: Int = 5,
        dueDay: Int = 20,
        color: AccountColor = .cyan,
        isArchived: Bool = false
    ) {
        self.id = id
        self.issuer = issuer
        self.holderName = holderName
        self.lastFour = lastFour
        self.balance = balance
        self.creditLimit = creditLimit
        self.apr = apr
        self.statementDay = statementDay
        self.dueDay = dueDay
        self.colorRaw = color.rawValue
        self.isArchived = isArchived
        self.createdAt = Date()
    }

    var color: AccountColor {
        get { AccountColor(rawValue: colorRaw) ?? .cyan }
        set { colorRaw = newValue.rawValue }
    }

    /// Balance relative to the credit limit, 0..100-ish percent.
    var utilization: Double {
        guard creditLimit > 0 else { return 0 }
        return balance / creditLimit * 100.0
    }

    var availableCredit: Double {
        max(creditLimit - balance, 0)
    }

    var maskedNumber: String {
        "•••• \\(lastFour)"
    }

    var isOverLimit: Bool {
        balance > creditLimit
    }
}