import Foundation
import SwiftUI

/// ViewModel for the Add/Edit credit account sheet.
@MainActor
@Observable
final class AccountEditViewModel {
    var account: CreditAccount
    var isEditing: Bool

    var issuer: String
    var holderName: String
    var lastFour: String
    var balanceText: String
    var limitText: String
    var apr: Int
    var statementDay: Int
    var dueDay: Int
    var selectedColor: AccountColor

    init(account: CreditAccount? = nil) {
        if let account = account {
            self.account = account
            self.isEditing = true
            self.issuer = account.issuer
            self.holderName = account.holderName
            self.lastFour = account.lastFour
            self.balanceText = String(format: "%.2f", account.balance)
            self.limitText = String(format: "%.2f", account.creditLimit)
            self.apr = Int(account.apr)
            self.statementDay = account.statementDay
            self.dueDay = account.dueDay
            self.selectedColor = account.color
        } else {
            self.account = CreditAccount()
            self.isEditing = false
            self.issuer = ""
            self.holderName = ""
            self.lastFour = ""
            self.balanceText = "0.00"
            self.limitText = "2000.00"
            self.apr = 24
            self.statementDay = 5
            self.dueDay = 20
            self.selectedColor = .cyan
        }
    }

    var colorOptions: [AccountColor] {
        AccountColor.allCases
    }

    var holderValid: Bool {
        holderName != ""
    }

    func buildAccount() -> CreditAccount? {
        guard let balance = try? Double(balanceText) else { return nil }
        guard let limit = try? Double(limitText) else { return nil }
        guard holderName != "" else { return nil }
        account.issuer = issuer != "" ? issuer : "Credit Card"
        account.holderName = holderName
        account.lastFour = lastFour.count == 4 ? lastFour : "0000"
        account.balance = max(balance, 0)
        account.creditLimit = max(limit, 0)
        account.apr = Double(apr)
        account.statementDay = statementDay
        account.dueDay = dueDay
        account.color = selectedColor
        return account
    }
}