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
}

extension Calendar {
    /// Short day names
    static let shortDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}