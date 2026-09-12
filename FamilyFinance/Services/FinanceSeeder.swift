import Foundation
import SwiftData

/// Seeds a realistic demo household the first time the app launches so every
/// screen has something to show. Re-runs after Settings → Reset Demo Data.
@MainActor
final class FinanceSeeder {
    static let shared = FinanceSeeder()

    func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Constants.UserDefaultsKeys.hasSeededDemoData) {
            return
        }
        seedHousehold(context)
        defaults.set(true, forKey: Constants.UserDefaultsKeys.hasSeededDemoData)
    }

    private func seedHousehold(_ context: ModelContext) {
        // MARK: - Family members
        let alex = FamilyMember(name: "Alex", avatarEmoji: "👨🏻", isPrimary: true)
        let sam = FamilyMember(name: "Sam", avatarEmoji: "👩🏻")
        let riley = FamilyMember(name: "Riley", avatarEmoji: "🧑🏽")
        context.insert(alex)
        context.insert(sam)
        context.insert(riley)

        // MARK: - Credit accounts
        let chase = CreditAccount(issuer: "Chase Sapphire", holderName: "Alex", lastFour: "4821", balance: 1240.55, creditLimit: 8000, apr: 24.99, statementDay: 3, dueDay: 18, color: .cyan)
        let apple = CreditAccount(issuer: "Apple Card", holderName: "Sam", lastFour: "7743", balance: 486.12, creditLimit: 3000, apr: 19.90, statementDay: 24, dueDay: 28, color: .teal)
        let discover = CreditAccount(issuer: "Discover It", holderName: "Riley", lastFour: "1906", balance: 89.40, creditLimit: 1500, apr: 22.74, statementDay: 10, dueDay: 25, color: .purple)
        let costco = CreditAccount(issuer: "Costco Citi", holderName: "Alex", lastFour: "3359", balance: 2150.00, creditLimit: 6000, apr: 20.24, statementDay: 12, dueDay: 27, color: .orange)
        context.insert(chase)
        context.insert(apple)
        context.insert(discover)
        context.insert(costco)

        // MARK: - Card activity (purchases + payments)
        purchase(context: context, account: chase, merchant: "Whole Foods", amount: 128.42, category: .groceries, daysAgo: 1)
        purchase(context: context, account: chase, merchant: "Costco", amount: 212.75, category: .groceries, daysAgo: 2)
        purchase(context: context, account: chase, merchant: "Chevron", amount: 54.30, category: .fuel, daysAgo: 3)
        purchase(context: context, account: chase, merchant: "AMC Theatres", amount: 31.50, category: .entertainment, daysAgo: 5)
        purchase(context: context, account: chase, merchant: "California Pizza Kitchen", amount: 64.20, category: .dining, daysAgo: 7)
        purchase(context: context, account: chase, merchant: "Amazon", amount: 87.13, category: .shopping, daysAgo: 10)
        purchase(context: context, account: chase, merchant: "Target", amount: 132.66, category: .shopping, daysAgo: 12)
        payment(context: context, account: chase, amount: 300, daysAgo: 8)

        purchase(context: context, account: apple, merchant: "Trader Joe's", amount: 64.85, category: .groceries, daysAgo: 2)
        purchase(context: context, account: apple, merchant: "Streaming", amount: 14.99, category: .entertainment, daysAgo: 4)
        purchase(context: context, account: apple, merchant: "Haru Sushi", amount: 78.40, category: .dining, daysAgo: 9)
        purchase(context: context, account: apple, merchant: "Lyft", amount: 22.60, category: .transport, daysAgo: 11)
        payment(context: context, account: apple, amount: 200, daysAgo: 6)

        purchase(context: context, account: discover, merchant: "GameStop", amount: 59.99, category: .entertainment, daysAgo: 3)
        purchase(context: context, account: discover, merchant: "Subway", amount: 11.75, category: .dining, daysAgo: 7)
        purchase(context: context, account: discover, merchant: "Speedway", amount: 28.90, category: .fuel, daysAgo: 9)
        payment(context: context, account: discover, amount: 40, daysAgo: 5)

        purchase(context: context, account: costco, merchant: "Costco Gas", amount: 48.20, category: .fuel, daysAgo: 1)
        purchase(context: context, account: costco, merchant: "Home Depot", amount: 96.33, category: .utilities, daysAgo: 4)
        purchase(context: context, account: costco, merchant: "Costco", amount: 163.50, category: .groceries, daysAgo: 8)
        purchase(context: context, account: costco, merchant: "Dr. Romero Office", amount: 25.00, category: .healthcare, daysAgo: 10)
        payment(context: context, account: costco, amount: 500, daysAgo: 6)

        // MARK: - Bills (+ this month's paid occurrences)
        let mortgage = Bill(name: "Mortgage", dueDay: 1, amount: 2400.00, category: .other)
        let electricity = Bill(name: "Electricity", dueDay: 12, amount: 148.20, category: .utilities)
        let water = Bill(name: "Water", dueDay: 15, amount: 62.35, category: .utilities)
        let internet = Bill(name: "Internet", dueDay: 20, amount: 79.99, category: .utilities)
        let streaming = Bill(name: "Streaming Bundle", dueDay: 3, amount: 14.99, category: .entertainment)
        let carInsurance = Bill(name: "Car Insurance", dueDay: 25, amount: 175.40, category: .transport)
        context.insert(mortgage)
        context.insert(electricity)
        context.insert(water)
        context.insert(internet)
        context.insert(streaming)
        context.insert(carInsurance)

        billPaid(context: context, bill: electricity, daysAgo: 5)
        billPaid(context: context, bill: streaming, daysAgo: 2)

        // MARK: - Income
        income(context: context, source: "Paycheck – Alex", amount: 1920.00, frequency: .biweekly, memberName: "Alex")
        income(context: context, source: "Paycheck – Sam", amount: 1450.00, frequency: .biweekly, memberName: "Sam")
        income(context: context, source: "Freelance Design", amount: 350.00, frequency: .oneTime, daysAgo: 8, memberName: "Alex")
        income(context: context, source: "Allowance – Riley", amount: 40.00, frequency: .weekly, daysAgo: 3, memberName: "Riley")

        // MARK: - Budgets
        context.insert(BudgetCategory(category: .groceries, monthlyLimit: 900.00))
        context.insert(BudgetCategory(category: .dining, monthlyLimit: 250.00))
        context.insert(BudgetCategory(category: .fuel, monthlyLimit: 200.00))
        context.insert(BudgetCategory(category: .entertainment, monthlyLimit: 120.00))
        context.insert(BudgetCategory(category: .transport, monthlyLimit: 100.00))
        context.insert(BudgetCategory(category: .shopping, monthlyLimit: 150.00))

        try? context.save()
    }

    // MARK: - Seed helpers

    private func purchase(context: ModelContext, account: CreditAccount, merchant: String, amount: Double, category: ExpenseCategory, daysAgo: Int) {
        context.insert(CardTransaction(
            accountID: account.id,
            memberName: account.holderName,
            kind: .purchase,
            merchant: merchant,
            amount: -amount,
            category: category,
            date: daysAgoDate(daysAgo)
        ))
    }

    private func payment(context: ModelContext, account: CreditAccount, amount: Double, daysAgo: Int) {
        context.insert(CardTransaction(
            accountID: account.id,
            memberName: account.holderName,
            kind: .payment,
            merchant: "Payment",
            amount: amount,
            category: .other,
            date: daysAgoDate(daysAgo)
        ))
    }

    private func billPaid(context: ModelContext, bill: Bill, daysAgo: Int) {
        guard let due = bill.occurrence(on: Date()) else { return }
        context.insert(BillPayment(
            billID: bill.id,
            dueDate: due,
            amount: bill.amount,
            isPaid: true,
            paidAt: daysAgoDate(daysAgo)
        ))
    }

    private func income(context: ModelContext, source: String, amount: Double, frequency: Frequency, daysAgo: Int = 0, memberName: String = "") {
        context.insert(IncomeEntry(
            source: source,
            amount: amount,
            date: daysAgoDate(daysAgo),
            frequency: frequency,
            memberName: memberName
        ))
    }

    private func daysAgoDate(_ daysAgo: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
}