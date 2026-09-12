import Foundation
import SwiftData

/// A person in the household. Credit cards can be assigned to members.
@Model
final class FamilyMember {
    var id: UUID
    var name: String
    var avatarEmoji: String
    var isPrimary: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Family Member",
        avatarEmoji: String = "👤",
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.isPrimary = isPrimary
        self.createdAt = Date()
    }
}