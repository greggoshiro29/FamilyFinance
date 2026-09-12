import Foundation
import SwiftUI

/// ViewModel for the Add/Edit bill sheet.
@MainActor
@Observable
final class BillEditViewModel {
    var bill: Bill
    var isEditing: Bool

    var name: String
    var amountText: String
    var dueDay: Int
    var category: ExpenseCategory
    var reminderDays: Int
    var isActive: Bool

    init(bill: Bill? = nil) {
        if let bill = bill {
            self.bill = bill
            self.isEditing = true
            self.name = bill.name
            self.amountText = String(format: "%.2f", bill.amount)
            self.dueDay = bill.dueDay
            self.category = bill.category
            self.reminderDays = bill.reminderDaysBefore
            self.isActive = bill.isActive
        } else {
            self.bill = Bill()
            self.isEditing = false
            self.name = ""
            self.amountText = "0.00"
            self.dueDay = 1
            self.category = .utilities
            self.reminderDays = Constants.defaultReminderDaysBefore
            self.isActive = true
        }
    }

    var categoryOptions: [ExpenseCategory] {
        ExpenseCategory.allCases
    }

    func buildBill() -> Bill? {
        guard let amount = try? Double(amountText) else { return nil }
        guard amount > 0 else { return nil }
        bill.name = name != "" ? name : "Bill"
        bill.amount = amount
        bill.dueDay = min(max(dueDay, 1), Constants.maxDueDay)
        bill.category = category
        bill.reminderDaysBefore = reminderDays
        bill.isActive = isActive
        bill.updatedAt = Date()
        return bill
    }
}