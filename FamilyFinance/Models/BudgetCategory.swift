import Foundation
import SwiftData

/// A monthly spending limit for one category.
@Model
final class BudgetCategory {
    var id: UUID
    var categoryRaw: String // ExpenseCategory rawValue
    var monthlyLimit: Double
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        category: ExpenseCategory = .groceries,
        monthlyLimit: Double = 500,
        isActive: Bool = true
    ) {
        self.id = id
        self.categoryRaw = category.rawValue
        self.monthlyLimit = monthlyLimit
        self.isActive = isActive
        self.createdAt = Date()
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .groceries }
        set { categoryRaw = newValue.rawValue }
    }
}