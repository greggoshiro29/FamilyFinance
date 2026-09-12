import Foundation

extension Date {
    /// Returns the next occurrence of the given hour/minute on or after this date
    func nextOccurrence(hour: Int, minute: Int, activeDays: Set<Int>) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        // Start from max(self, now)
        var base = self > now ? self : now

        // Check up to 8 days ahead
        for _ in 0..<8 {
            let weekday = calendar.component(.weekday, from: base)
            if activeDays.contains(weekday) {
                var comps = calendar.dateComponents([.year, .month, .day], from: base)
                comps.hour = hour
                comps.minute = minute
                comps.second = 0
                if let candidate = calendar.date(from: comps), candidate > now {
                    return candidate
                }
            }
            // Advance to start of next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: base) else { break }
            base = calendar.startOfDay(for: nextDay)
        }
        return nil
    }

    /// Format as 12-hour time string (e.g., "7:30 AM")
    var formattedTime12h: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    /// "2025-06" style month key used to group transactions/occurrences.
    var periodKey: String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: self)
        return String(format: "%04d-%02d", comps.yearValue, comps.monthValue)
    }

    /// "2025-06-15" style day key used to tag calendar cells.
    var dayKey: String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d-%02d-%02d", comps.yearValue, comps.monthValue, comps.dayValue)
    }

    /// "Jun 15" style short label.
    var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// "June 2025" style label used as the calendar header.
    var monthYearLabel: String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: self)
        let name = Calendar.monthNames[comps.monthValue - 1]
        return "\(name) \(comps.yearValue)"
    }

    /// True when this date falls in the same calendar month as the other.
    func sameMonth(as other: Date) -> Bool {
        periodKey == other.periodKey
    }

    /// Day-of-month integer (1..31).
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }
}

extension DateComponents {
    /// Unwrapped accessors for fields we always request before reading.
    /// DateComponents stores every field as optional.
    var yearValue: Int {
        year ?? 0
    }

    var monthValue: Int {
        month ?? 0
    }

    var dayValue: Int {
        day ?? 0
    }

    var hourValue: Int {
        hour ?? 0
    }

    var minuteValue: Int {
        minute ?? 0
    }
}

extension Calendar {
    /// Short day names
    static let shortDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    /// Full month names (index 0 = January).
    static let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    /// Single-letter weekday column headers, index 0 = Sunday.
    static let shortWeekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    /// Number of days in the given month.
    func daysInMonth(year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = date(from: comps) else { return 30 }
        var count = 28
        while true {
            comps.day = count + 1
            guard let probe = date(from: comps) else { return count }
            let probeMonth = dateComponents([.month], from: probe).monthValue
            if probeMonth != month {
                return count
            }
            count += 1
        }
    }

    /// Weekday offset of the first day of a month: 0 = Sunday … 6 = Saturday.
    func firstWeekdayOffset(year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = date(from: comps) else { return 0 }
        return component(.weekday, from: first) - 1
    }
}

extension Double {
    /// "-$12.34" style formatting (no thousands grouping).
    var currencyString: String {
        let isNegative = self < 0
        let magnitude = isNegative ? -self : self
        let sign = isNegative ? "-" : ""
        let formatted = String(format: "%.2f", magnitude)
        return "\(sign)\(Constants.currencySymbol)\(formatted)"
    }

    /// Signed "+$50.00" / "-$12.34" formatting for transaction rows.
    var signedCurrencyString: String {
        let isNegative = self < 0
        let magnitude = isNegative ? -self : self
        let sign = isNegative ? "-" : "+"
        let formatted = String(format: "%.2f", magnitude)
        return "\(sign)\(Constants.currencySymbol)\(formatted)"
    }

    /// "62%" rounding used on utilization/progress labels.
    var percentString: String {
        String(format: "%.0f%%", self)
    }
}