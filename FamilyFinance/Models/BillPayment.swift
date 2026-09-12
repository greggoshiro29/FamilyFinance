import Foundation
import SwiftData

/// Tracks whether one bill occurrence was paid. One row per month per bill.
@Model
final class BillPayment {
    var id: UUID
    var billID: UUID
    var dueDate: Date // The due date this payment applies to
    var amount: Double
    var isPaid: Bool
    var paidAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        billID: UUID,
        dueDate: Date,
        amount: Double = 0,
        isPaid: Bool = false,
        paidAt: Date? = nil
    ) {
        self.id = id
        self.billID = billID
        self.dueDate = dueDate
        self.amount = amount
        self.isPaid = isPaid
        self.paidAt = paidAt
        self.createdAt = Date()
    }
}