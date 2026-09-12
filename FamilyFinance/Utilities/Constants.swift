import Foundation

/// Central app constants and shared value enums for FamilyFinance.
enum Constants {
    /// Default currency symbol shown in money figures.
    static let currencySymbol = "$"

    /// Currency symbols selectable in Settings.
    static let currencySymbols: [String] = ["$", "€", "£", "¥", "₹", "R$"]

    /// Default how many days before a bill's due date the reminder fires.
    static let defaultReminderDaysBefore: Int = 3

    /// Default avatar emoji options shown in the member editor.
    static let avatarOptions: [String] = ["👤", "👩🏻", "👨🏻", "🧑🏽", "🧕🏽", "👵🏻", "👧🏽", "👦🏻"]

    /// Notification category for bill reminders.
    static let reminderCategoryIdentifier = "BILL_REMINDER_CATEGORY"

    /// Notification identifier prefix for one bill reminder.
    static let reminderIdentifierPrefix = "com.familyfinance.reminder"

    /// Highest allowed payment due-day in a month.
    static let maxDueDay: Int = 28

    /// UserDefaults keys.
    struct UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasSeededDemoData = "hasSeededDemoData"
        static let householdName = "householdName"
        static let currencySymbol = "currencySymbol"
        static let reminderNotificationsEnabled = "reminderNotificationsEnabled"
        static let defaultReminderDays = "defaultReminderDays"
    }
}

/// A credit-card line item: money out (purchase) or money in (payment).
enum TransactionKind: String, Codable, CaseIterable {
    case purchase = "Purchase"
    case payment = "Payment"

    var systemImage: String {
        switch self {
        case .purchase: return "cart"
        case .payment: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .purchase: return .orange
        case .payment: return .green
        }
    }
}

/// Spending categories used by transactions and budget limits.
enum ExpenseCategory: String, Codable, CaseIterable {
    case groceries = "Groceries"
    case dining = "Dining Out"
    case fuel = "Fuel"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case healthcare = "Health"
    case kids = "Kids"
    case other = "Other"

    /// SF Symbol name shown beside each category row.
    var systemImage: String {
        switch self {
        case .groceries: return "cart"
        case .dining: return "fork.knife"
        case .fuel: return "fuelpump.fill"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .utilities: return "bolt.fill"
        case .healthcare: return "cross.circle.fill"
        case .kids: return "heart.fill"
        case .other: return "sparkles.fill"
        }
    }

    var color: Color {
        switch self {
        case .groceries: return .green
        case .dining: return .orange
        case .fuel: return .yellow
        case .transport: return .blue
        case .shopping: return .pink
        case .entertainment: return .purple
        case .utilities: return .teal
        case .healthcare: return .red
        case .kids: return .cyan
        case .other: return .gray
        }
    }
}

/// How often an income source repeats.
enum Frequency: String, Codable, CaseIterable {
    case oneTime = "One Time"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"

    var displayName: String {
        rawValue
    }
}

/// Accent colors a credit account card can use.
enum AccountColor: String, Codable, CaseIterable {
    case cyan = "Cyan"
    case teal = "Teal"
    case green = "Green"
    case purple = "Purple"
    case orange = "Orange"
    case pink = "Pink"

    var color: Color {
        switch self {
        case .cyan: return .cyan
        case .teal: return .teal
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        }
    }
}