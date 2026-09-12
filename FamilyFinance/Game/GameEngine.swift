import Foundation
import SwiftUI

/// Core game engine managing aliens, timing, shots, and cooldowns.
/// Runs on a display link-driven loop that updates alien positions and checks game conditions.
@MainActor
final class GameEngine: ObservableObject {
    @Published var aliens: [AlienState] = []
    @Published var kills: Int = 0
    @Published var misses: Int = 0
    @Published var requiredKills: Int = Constants.defaultRequiredKills
    @Published var isGameOver: Bool = false
    @Published var isMissionComplete: Bool = false
    @Published var lastShotResult: ShotResult?
    @Published var showMiss: Bool = false
    @Published var showExplosion: Bool = false
    @Published var explosionPosition: CGPoint = .zero
    @Published var elapsedTime: TimeInterval = 0
    @Published var gameStartTime: Date?

    // Anti-cheat
    private(set) var lastShotTime: Date = .distantPast
    private(set) var totalShots: Int = 0
    private(set) var shotCooldownActive: Bool = false

    private var difficulty: Difficulty = .normal
    private var spawnTimer: Timer?
    private var updateTimer: Timer?
    private var screenHeight: CGFloat = 800
    private var screenWidth: CGFloat = 400
    private var lastUpdateTime: Date?
    private var pauseTime: Date?
    private var gameActive: Bool = false

    // Alien spawn tracking
    private var lastSpawnTime: Date = .distantPast
    private var spawnInterval: TimeInterval = 2.0

    // Targeting reticle position — center of the game area, lower on screen
    // (55% down) so the shooting lane sits closer to the player's thumb.
    var reticleCenter: CGPoint {
        CGPoint(x: screenWidth / 2, y: screenHeight * 0.55)
    }

    init() {}

    // MARK: - Game Lifecycle

    func startGame(requiredKills: Int, difficulty: Difficulty, screenSize: CGSize) {
        reset()
        self.requiredKills = requiredKills
        self.difficulty = difficulty
        self.screenWidth = screenSize.width
        self.screenHeight = screenSize.height
        self.gameStartTime = Date()
        self.gameActive = true
        self.lastUpdateTime = Date()

        // Spawn first alien after a short delay
        spawnInterval = TimeInterval.random(in: Constants.alienSpawnIntervalRange)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSpawn()
            }
        }

        // Update loop at ~60fps
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
    }

    func stopGame() {
        gameActive = false
        spawnTimer?.invalidate()
        updateTimer?.invalidate()
        spawnTimer = nil
        updateTimer = nil
    }

    func reset() {
        stopGame()
        aliens = []
        kills = 0
        misses = 0
        isGameOver = false
        isMissionComplete = false
        lastShotResult = nil
        showMiss = false
        showExplosion = false
        elapsedTime = 0
        totalShots = 0
        lastShotTime = .distantPast
        shotCooldownActive = false
        gameStartTime = nil
        lastSpawnTime = .distantPast
        pauseTime = nil
    }

    // MARK: - Update Loop

    private func update() {
        guard gameActive, let lastUpdate = lastUpdateTime else { return }
        let now = Date()

        // Check if game was paused too long
        if let paused = pauseTime {
            if now.timeIntervalSince(paused) > Constants.maxPauseDuration {
                // Reset current alien but keep score
                aliens.removeAll()
                lastSpawnTime = .distantPast
            }
            pauseTime = nil
        }

        let dt = now.timeIntervalSince(lastUpdate)
        lastUpdateTime = now

        if let start = gameStartTime {
            elapsedTime = now.timeIntervalSince(start)
        }

        // Update alien positions
        var updatedAliens: [AlienState] = []
        for var alien in aliens {
            guard alien.isAlive else { continue }

            // Vertical descent (base motion)
            alien.position.y += alien.speed * CGFloat(dt)

            // Remove aliens that have exited the bottom
            if alien.position.y > screenHeight + 100 {
                continue
            }

            // Horizontal steering: glide toward the alien's target lane so it
            // crosses in front of the reticle with a clear diagonal sweep and
            // visible banking as it turns.
            let desiredX = alien.targetX
            let dx = desiredX - alien.position.x
            let steerStrength: CGFloat = 2.6
            let steer = dx * min(steerStrength * CGFloat(dt), 1.0)
            alien.position.x += steer

            // Turn head/tail inline with the true trajectory. With head-down
            // art, positive rotationEffect (clockwise) swings the head left, so
            // we NEGATE the heading: that way the head (bottom of image) leads
            // the direction of travel and the tail trails behind.
            let hVel = steer / max(dt, 0.0001)
            let vVel = alien.speed
            let headingDeg = atan2(hVel, vVel) * 180 / .pi
            // Allow nearly-full sideways alignment so the head leads even when
            // entering the screen flying horizontally.
            let maxBank: CGFloat = 85
            alien.rotation = min(max(-headingDeg, -maxBank), maxBank)

            updatedAliens.append(alien)
        }
        aliens = updatedAliens

        // Update cooldown
        if shotCooldownActive && now.timeIntervalSince(lastShotTime) >= Constants.shotCooldown {
            shotCooldownActive = false
        }
    }

    // MARK: - Spawning

    private func checkSpawn() {
        let now = Date()
        guard gameActive,
              now.timeIntervalSince(lastSpawnTime) >= spawnInterval,
              aliens.count < 2, // Max 2 aliens on screen at once
              !isGameOver,
              !isMissionComplete else { return }

        spawnAlien()
        lastSpawnTime = now
        spawnInterval = TimeInterval.random(in: Constants.alienSpawnIntervalRange)
    }

    private func spawnAlien() {
        let type = AlienType.allCases.randomElement() ?? .saucer
        let baseSpeed: CGFloat = 130 + CGFloat.random(in: 0...40) // points/sec
        let speed = baseSpeed * type.speedModifier * CGFloat(difficulty.speedMultiplier)
        let startX = CGFloat.random(in: 50...(screenWidth - 50))

        // Steering target: 50% of aliens steer through the reticle lane
        // (hittable), while 50% fly off to one side and never cross the
        // bullseye (unhittable), adding variety and forcing the player to
        // pick their shots.
        let reticleX = screenWidth / 2
        let targetX: CGFloat
        if Int.random(in: 0..<100) < 50 {
            // Hittable: steer through the reticle lane
            targetX = reticleX + CGFloat.random(in: -60...60)
        } else {
            // Unhittable: pass off to one side, clear of the bullseye.
            // Pick the left or right half and stay out of the reticle lane.
            let centerLaneHalfWidth: CGFloat = 70
            if Bool.random() {
                targetX = CGFloat.random(in: 70...(reticleX - centerLaneHalfWidth))
            } else {
                targetX = CGFloat.random(in: (reticleX + centerLaneHalfWidth)...(screenWidth - 70))
            }
        }

        let alien = AlienState(type: type, startX: startX, speed: speed, targetX: targetX)
        aliens.append(alien)
    }

    // MARK: - Shooting

    /// Attempt to fire at the current aliens. Returns the shot result.
    func fire() -> ShotResult {
        let now = Date()

        // Check cooldown
        if shotCooldownActive {
            return .cooldown
        }

        lastShotTime = now
        shotCooldownActive = true
        totalShots += 1

        // Find an alien whose body overlaps the bullseye. The intent: a hit
        // registers when ANY part of the alien overlaps the reticle.
        // bullseyeRadius ~ 40 (reticle is 80pt across); add the alien's half
        // size so overlapping body counts as a hit.
        let bullseyeRadius: CGFloat = 40
        let alienBodyRadius: CGFloat = 30 // max half-size of a ship

        for (index, alien) in aliens.enumerated() where alien.isAlive && !alien.hasBeenHit {
            // Distance between the bullseye and the alien's center.
            let distance = hypot(alien.position.x - reticleCenter.x, alien.position.y - reticleCenter.y)
            // A hit when the bullseye reaches the alien's body (not just its center).
            if distance < bullseyeRadius + alienBodyRadius {
                // HIT!
                aliens[index].isAlive = false
                aliens[index].hasBeenHit = true
                kills += 1
                explosionPosition = reticleCenter  // point of contact on the bullseye
                showExplosion = true

                // Hide explosion after the (longer) particle burst plays out
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.showExplosion = false
                }

                // Remove from array after explosion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.aliens.removeAll { !$0.isAlive }
                }

                // Check victory — the game ends as soon as the required number
                // of aliens is destroyed (no minimum duration).
                if kills >= requiredKills {
                    isMissionComplete = true
                    isGameOver = true
                    stopGame()
                }

                lastShotResult = .hit
                return .hit
            }
        }

        // MISS
        misses += 1
        showMiss = true
        lastShotResult = .miss

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showMiss = false
        }

        return .miss
    }

    // MARK: - Pause Management

    func handleAppBackground() {
        pauseTime = Date()
    }

    func handleAppForeground() {
        // pauseTime is cleared in update() after checking duration
        if let paused = pauseTime, Date().timeIntervalSince(paused) > Constants.maxPauseDuration {
            aliens.removeAll()
            lastSpawnTime = .distantPast
        }
    }

    // MARK: - State

    var progress: Double {
        guard requiredKills > 0 else { return 0 }
        return Double(kills) / Double(requiredKills)
    }

    var accuracy: Double {
        let total = kills + misses
        guard total > 0 else { return 0 }
        return Double(kills) / Double(total) * 100.0
    }
}

enum ShotResult {
    case hit
    case miss
    case cooldown
}