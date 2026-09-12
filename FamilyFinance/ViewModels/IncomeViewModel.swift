import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the income tracker.
@MainActor
@Observable
final class IncomeViewModel {
    var entries: [IncomeEntry] = []
    var showingAddIncome = false
    var editingIncome: IncomeEntry?

    func refresh(context: ModelContext) {
        do {
            entries = try context.fetch(FetchDescriptor<IncomeEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        } catch {
            print("Failed to fetch income: \(error)")
        }
    }

    // MARK: - Totals

    var monthEntries: [IncomeEntry] {
        entries.filter { $0.date.sameMonth(as: Date()) }
    }

    var monthTotal: Double {
        monthEntries.reduce(0) { $0 + $1.amount }
    }

    var weekTotal: Double {
        let cutoff = Date().addingTimeInterval(-604800)
        return entries.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.amount }
    }

    /// Rough monthly view of recurring sources (as entered per occurrence).
    var recurringTotal: Double {
        entries.filter { $0.frequency != .oneTime }.reduce(0) { $0 + $1.amount }
    }

    var recentEntries: [IncomeEntry] {
        var result: [IncomeEntry] = []
        let end = min(entries.count, 12)
        for i in 0..<end {
            result.append(entries[i])
        }
        return result
    }

    var sourceCount: Int {
        monthEntries.count
    }

    // MARK: - Persistence

    func saveIncome(_ entry: IncomeEntry, context: ModelContext) {
        if !entries.contains(where: { $0.id == entry.id }) {
            context.insert(entry)
        }
        try? context.save()
        refresh(context: context)
    }

    func deleteIncome(_ entry: IncomeEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
        refresh(context: context)
    }
}