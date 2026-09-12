import Foundation
import SwiftUI

/// ViewModel for the Add/Edit income entry sheet.
@MainActor
@Observable
final class IncomeEditViewModel {
    var entry: IncomeEntry
    var isEditing: Bool

    var source: String
    var amountText: String
    var frequency: Frequency
    var memberName: String
    var day: Int
    var month: Int
    var year: Int

    init(entry: IncomeEntry? = nil) {
        if let entry = entry {
            self.entry = entry
            self.isEditing = true
            self.source = entry.source
            self.amountText = String(format: "%.2f", entry.amount)
            self.frequency = entry.frequency
            self.memberName = entry.memberName
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: entry.date)
            self.day = comps.day
            self.month = comps.month
            self.year = comps.year
        } else {
            self.entry = IncomeEntry()
            self.isEditing = false
            self.source = ""
            self.amountText = "0.00"
            self.frequency = .oneTime
            self.memberName = ""
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            self.day = comps.day
            self.month = comps.month
            self.year = comps.year
        }
    }

    var frequencyOptions: [Frequency] {
        Frequency.allCases
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

    func buildEntry() -> IncomeEntry? {
        guard let amount = try? Double(amountText) else { return nil }
        guard amount > 0 else { return nil }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12
        comps.minute = 0
        guard let date = Calendar.current.date(from: comps) else { return nil }

        entry.source = source != "" ? source : "Income"
        entry.amount = amount
        entry.date = date
        entry.frequency = frequency
        entry.memberName = memberName
        return entry
    }
}