import Foundation
import SwiftData

/// One income entry: a paycheck, side hustle, allowance…
@Model
final class IncomeEntry {
    var id: UUID
    var source: String
    var amount: Double // Always stored positive
    var date: Date
    var frequencyRaw: String // Frequency rawValue
    var memberName: String
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        source: String = "Income",
        amount: Double = 0,
        date: Date = Date(),
        frequency: Frequency = .oneTime,
        memberName: String = "",
        note: String = ""
    ) {
        self.id = id
        self.source = source
        self.amount = amount
        self.date = date
        self.frequencyRaw = frequency.rawValue
        self.memberName = memberName
        self.note = note
        self.createdAt = Date()
    }

    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .oneTime }
        set { frequencyRaw = newValue.rawValue }
    }
}