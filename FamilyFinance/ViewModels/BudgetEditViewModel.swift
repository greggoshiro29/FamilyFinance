import Foundation
import SwiftUI

/// ViewModel for the Add/Edit budget sheet.
@MainActor
@Observable
final class BudgetEditViewModel {
    var budget: BudgetCategory
    var isEditing: Bool

    var category: ExpenseCategory
    var monthlyLimitText: String

    init(budget: BudgetCategory? = nil) {
        if let budget = budget {
            self.budget = budget
            self.isEditing = true
            self.category = budget.category
            self.monthlyLimitText = String(format: "%.2f", budget.monthlyLimit)
        } else {
            self.budget = BudgetCategory()
            self.isEditing = false
            self.category = .groceries
            self.monthlyLimitText = "200.00"
        }
    }

    var categoryOptions: [ExpenseCategory] {
        ExpenseCategory.allCases
    }

    func buildBudget() -> BudgetCategory? {
        guard let limit = try? Double(monthlyLimitText) else { return nil }
        guard limit > 0 else { return nil }
        budget.category = category
        budget.monthlyLimit = limit
        return budget
    }
}