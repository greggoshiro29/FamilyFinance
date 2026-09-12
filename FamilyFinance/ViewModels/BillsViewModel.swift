import Foundation
import SwiftUI
import SwiftData

/// One bill occurrence for a calendar month, with its payment state.
struct DueBill: Identifiable {
    let id: UUID
    let bill: Bill
    let dueDate: Date
    let payment: BillPayment?

    var isPaid: Bool {
        payment?.isPaid ?? false
    }
}

/// Builds the list of bill occurrences inside `month` (in bill order).
func dueBillsInMonth(bills: [Bill], payments: [BillPayment], month: Date) -> [DueBill] {
    var result: [DueBill] = []
    for bill in bills {
        guard bill.isActive else { continue }
        guard let due = bill.occurrence(on: month) else { continue }
        guard due.sameMonth(as: month) else { continue }
        let payment = payments.first { $0.billID == bill.id && $0.dueDate.sameMonth(as: due) }
        result.append(DueBill(id: UUID(), bill: bill, dueDate: due, payment: payment))
    }
    return result
}

/// ViewModel for the bill payment calendar.
@MainActor
@Observable
final class BillsViewModel {
    var month = Date()
    var bills: [Bill] = []
    var payments: [BillPayment] = []
    var showingAddBill = false
    var editingBill: Bill?

    func refresh(context: ModelContext) {
        do {
            bills = try context.fetch(FetchDescriptor<Bill>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch bills: \(error)")
        }
        do {
            payments = try context.fetch(FetchDescriptor<BillPayment>(sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            print("Failed to fetch bill payments: \(error)")
        }
    }

    func shiftMonth(by delta: Int) {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: month)
        let total = comps.yearValue * 12 + (comps.monthValue - 1) + delta
        comps.year = total / 12
        comps.month = total % 12 + 1
        comps.day = 1
        month = calendar.date(from: comps) ?? month
    }

    // MARK: - Calendar

    var visibleDueBills: [DueBill] {
        dueBillsInMonth(bills: bills, payments: payments, month: month)
    }

    var dueCount: Int {
        visibleDueBills.count
    }

    var unpaidCount: Int {
        visibleDueBills.filter { !$0.isPaid }.count
    }

    var unpaidTotal: Double {
        visibleDueBills.filter { !$0.isPaid }.reduce(0) { $0 + $1.bill.amount }
    }

    /// 42 flattened cells (leading nils) for the month grid.
    var monthGrid: [Date?] {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: month)
        let days = calendar.daysInMonth(year: comps.yearValue, month: comps.monthValue)
        let offset = calendar.firstWeekdayOffset(year: comps.yearValue, month: comps.monthValue)
        var cells: [Date?] = []
        for _ in 0..<offset {
            cells.append(nil)
        }
        for day in 1...days {
            comps.day = day
            if let date = calendar.date(from: comps) {
                cells.append(date)
            }
        }
        while cells.count < 42 {
            cells.append(nil)
        }
        return cells
    }

    /// Day keys (e.g. "2025-06-15") that have an UNPAID bill due.
    var unpaidDayKeys: Set<String> {
        var keys: Set<String> = []
        for due in visibleDueBills {
            if !due.isPaid {
                keys.insert(due.dueDate.dayKey)
            }
        }
        return keys
    }

    /// Day keys that have a PAID bill due.
    var paidDayKeys: Set<String> {
        var keys: Set<String> = []
        for due in visibleDueBills {
            if due.isPaid {
                keys.insert(due.dueDate.dayKey)
            }
        }
        return keys
    }

    // MARK: - Persistence

    func togglePaid(_ due: DueBill, context: ModelContext) {
        if due.isPaid {
            if let payment = due.payment {
                payment.isPaid = false
                payment.paidAt = nil
                try? context.save()
            }
        } else {
            if let payment = due.payment {
                payment.isPaid = true
                payment.paidAt = Date()
            } else {
                context.insert(BillPayment(
                    billID: due.bill.id,
                    dueDate: due.dueDate,
                    amount: due.bill.amount,
                    isPaid: true,
                    paidAt: Date()
                ))
            }
            try? context.save()
        }
        refresh(context: context)
    }

    func saveBill(_ bill: Bill, context: ModelContext) {
        if !bills.contains(where: { $0.id == bill.id }) {
            context.insert(bill)
        }
        bill.updatedAt = Date()
        try? context.save()
        refresh(context: context)
    }

    func deleteBill(_ bill: Bill, context: ModelContext) {
        for payment in payments.filter { $0.billID == bill.id } {
            context.delete(payment)
            BillReminderScheduler.shared.cancel(bill)
        }
        context.delete(bill)
        try? context.save()
        refresh(context: context)
    }
}