import Foundation
import SwiftData

/// A recurring household bill (rent, utilities, subscriptions…).
@Model
final class Bill {
    var id: UUID
    var name: String
    var dueDay: Int // Day of month the payment is due (1..28)
    var amount: Double
    var categoryRaw: String // ExpenseCategory rawValue
    var reminderDaysBefore: Int // 0 = remind on due day
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Bill",
        dueDay: Int = 1,
        amount: Double = 0,
        category: ExpenseCategory = .utilities,
        reminderDaysBefore: Int = Constants.defaultReminderDaysBefore,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.dueDay = dueDay
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.reminderDaysBefore = reminderDaysBefore
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .utilities }
        set { categoryRaw = newValue.rawValue }
    }

    /// The due date for the calendar month containing `on`.
    func occurrence(on: Date) -> Date? {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: on)
        let days = calendar.daysInMonth(year: comps.yearValue, month: comps.monthValue)
        comps.day = min(dueDay, days)
        comps.hour = 9
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps)
    }
}