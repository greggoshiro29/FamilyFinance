import Foundation
import SwiftUI
import SwiftData

/// One budget category with its spent-vs-limit numbers for the month.
struct BudgetStatus: Identifiable {
    let id: UUID
    let budget: BudgetCategory
    let spent: Double

    var remaining: Double {
        budget.monthlyLimit - spent
    }

    var ratio: Double {
        guard budget.monthlyLimit > 0 else { return 0 }
        return spent / budget.monthlyLimit * 100.0
    }
}

/// ViewModel for category budgets.
@MainActor
@Observable
final class BudgetsViewModel {
    var budgets: [BudgetCategory] = []
    var transactions: [CardTransaction] = []
    var statuses: [BudgetStatus] = []
    var showingAddBudget = false
    var editingBudget: BudgetCategory?

    func refresh(context: ModelContext) {
        do {
            budgets = try context.fetch(FetchDescriptor<BudgetCategory>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch budgets: \(error)")
        }
        do {
            transactions = try context.fetch(FetchDescriptor<CardTransaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
        var list: [BudgetStatus] = []
        for budget in budgets {
            if budget.isActive {
                let spent = transactions.filter { $0.isPurchase && $0.category == budget.category && $0.date.sameMonth(as: Date()) }.reduce(0) { $0 + (-$1.amount) }
                list.append(BudgetStatus(id: UUID(), budget: budget, spent: spent))
            }
        }
        statuses = list
    }

    var totalLimit: Double {
        budgets.reduce(0) { $0 + $1.monthlyLimit }
    }

    var totalSpent: Double {
        statuses.reduce(0) { $0 + $1.spent }
    }

    var totalRemaining: Double {
        totalLimit - totalSpent
    }

    // MARK: - Persistence

    func saveBudget(_ budget: BudgetCategory, context: ModelContext) {
        if !budgets.contains(where: { $0.id == budget.id }) {
            context.insert(budget)
        }
        try? context.save()
        refresh(context: context)
    }

    func deleteBudget(_ budget: BudgetCategory, context: ModelContext) {
        context.delete(budget)
        try? context.save()
        refresh(context: context)
    }
}