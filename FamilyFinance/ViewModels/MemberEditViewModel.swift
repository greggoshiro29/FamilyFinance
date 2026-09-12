import Foundation
import SwiftUI

/// ViewModel for the Add/Edit family member sheet.
@MainActor
@Observable
final class MemberEditViewModel {
    var member: FamilyMember
    var isEditing: Bool

    var name: String
    var avatarEmoji: String
    var isPrimary: Bool

    init(member: FamilyMember? = nil) {
        if let member = member {
            self.member = member
            self.isEditing = true
            self.name = member.name
            self.avatarEmoji = member.avatarEmoji
            self.isPrimary = member.isPrimary
        } else {
            self.member = FamilyMember()
            self.isEditing = false
            self.name = ""
            self.avatarEmoji = Constants.avatarOptions[0]
            self.isPrimary = false
        }
    }

    var avatarOptions: [String] {
        Constants.avatarOptions
    }

    func buildMember() -> FamilyMember? {
        guard name != "" else { return nil }
        member.name = name
        member.avatarEmoji = avatarEmoji
        member.isPrimary = isPrimary
        return member
    }
}