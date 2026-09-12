import Foundation

/// Represents the live state of an active game session.
/// Not persisted to SwiftData — stored via UserDefaults for crash recovery.
struct GameState: Codable {
    var alarmID: UUID
    var requiredKills: Int
    var kills: Int
    var misses: Int
    var startTime: Date
    var isActive: Bool
    var difficulty: Difficulty

    init(alarmID: UUID, requiredKills: Int, difficulty: Difficulty) {
        self.alarmID = alarmID
        self.requiredKills = requiredKills
        self.kills = 0
        self.misses = 0
        self.startTime = Date()
        self.isActive = true
        self.difficulty = difficulty
    }
}

/// Represents a single alien in the game
struct AlienState: Identifiable {
    let id: UUID
    var position: CGPoint
    var speed: CGFloat // points per second
    var alienType: AlienType
    var isAlive: Bool
    var hasBeenHit: Bool
    /// Bank angle in degrees (visual roll/turn while flying).
    var rotation: CGFloat
    /// Horizontal position the alien steers toward while descending, so it
    /// crosses in front of the targeting reticle more often.
    var targetX: CGFloat

    init(type: AlienType, startX: CGFloat, speed: CGFloat, targetX: CGFloat) {
        self.id = UUID()
        self.position = CGPoint(x: startX, y: -50) // Start above screen
        self.speed = speed
        self.alienType = type
        self.isAlive = true
        self.hasBeenHit = false
        self.rotation = 0
        self.targetX = targetX
    }
}

enum AlienType: Int, CaseIterable {
    case saucer = 0
    case diamond = 1
    case invader = 2
    case orb = 3
    case fighter = 4

    /// Size multiplier relative to base alien size
    var size: CGFloat {
        switch self {
        case .saucer: return 1.0
        case .diamond: return 0.85
        case .invader: return 1.1
        case .orb: return 0.7
        case .fighter: return 0.95
        }
    }

    /// Base speed modifier
    var speedModifier: CGFloat {
        switch self {
        case .saucer: return 1.0
        case .diamond: return 1.1
        case .invader: return 0.9
        case .orb: return 1.3
        case .fighter: return 1.05
        }
    }
}