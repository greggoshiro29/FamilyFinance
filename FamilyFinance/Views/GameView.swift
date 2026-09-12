import SwiftUI

/// One-button space shooter game where the player fires at aliens crossing a fixed reticle.
struct GameView: View {
    let alarm: AlarmModel
    let onComplete: () -> Void

    @StateObject private var engine = GameEngine()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showCompletion = false
    @State private var completionResult: GameResult?
    @State private var showEmergencyConfirm = false
    @State private var emergencyHoldProgress: CGFloat = 0
    @State private var showWarning = true

    // Test mode: reduce kill count for UI tests
    @AppStorage("testRequiredKills") private var testRequiredKills: Int = 0

    private var effectiveRequiredKills: Int {
        testRequiredKills > 0 ? testRequiredKills : alarm.requiredKills
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Star field
                StarField()
                    .ignoresSafeArea()

                // Game content
                VStack(spacing: 0) {
                    // HUD
                    gameHUD
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Game area with aliens and reticle
                    gameArea(size: geometry.size)
                        .frame(maxHeight: .infinity)

                    // Fire button
                    fireButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }

                // MISS overlay
                if engine.showMiss {
                    Text("MISS")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.red.opacity(0.8))
                        .shadow(color: .red, radius: 10)
                        .transition(.scale.combined(with: .opacity))
                }

                // Emergency exit
                emergencyExit

                // Pre-game warning — flashes for the first 2 seconds.
                if showWarning {
                    WarningOverlay(requiredKills: effectiveRequiredKills)
                        .transition(.opacity)
                }
            }
        }
        .statusBarHidden()
        .onDisappear {
            engine.stopGame()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                engine.handleAppForeground()
            case .inactive, .background:
                engine.handleAppBackground()
            @unknown default:
                break
            }
        }
        .onChange(of: engine.isMissionComplete) { _, complete in
            if complete {
                handleCompletion()
            }
        }
        .fullScreenCover(isPresented: $showCompletion) {
            if let result = completionResult {
                CompletionView(result: result) {
                    onComplete()
                }
            }
        }
    }

    // MARK: - HUD

    private var gameHUD: some View {
        VStack(spacing: 6) {
            HStack {
                // Kill counter
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALIENS DESTROYED")
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text("\(engine.kills) / \(effectiveRequiredKills)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }

                Spacer()

                // Elapsed time
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TIME")
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text(formatTime(engine.elapsedTime))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, CGFloat(engine.progress) * geo.size.width), height: 8)
                        .animation(.easeOut(duration: 0.2), value: engine.progress)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Game Area

    /// The game area is the single coordinate space the engine uses. Measuring
    /// its real (rendered) size and feeding it to the engine — instead of
    /// full-screen bounds — keeps alien positions, the bullseye, and hit
    /// testing all in one aligned space.
    private func gameArea(size: CGSize) -> some View {
        GeometryReader { geo in
            ZStack {
                // Aliens
                ForEach(engine.aliens) { alien in
                    AlienView.view(for: alien.alienType, size: 50, rotation: alien.rotation)
                        .position(alien.position)
                        .opacity(alien.isAlive ? 1 : 0)
                        .animation(.easeOut(duration: 0.2), value: alien.isAlive)
                }

                // Targeting reticle drawn at the engine's true hit-test center.
                TargetingReticle(size: 80)
                    .position(engine.reticleCenter)
                    .accessibilityLabel("Targeting reticle. Tap the FIRE button when an alien overlaps this target.")

                // Explosion — rendered in the SAME coordinate space as the
                // reticle so the particle burst lands exactly on the bullseye.
                // frame() BEFORE scaleEffect() so the enlarged burst isn't
                // clipped, then position() anchors it exactly at the reticle.
                // scaleEffect(4) = another 100% bigger vs the prior 2x build.
                if engine.showExplosion {
                    ExplosionView()
                        .frame(width: 240, height: 240)
                        .scaleEffect(4.0)
                        .position(engine.explosionPosition)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                // Show a 2-second warning first, then start the game so the
                // first alien only begins flying after the warning clears.
                showWarning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    guard showWarning else { return }
                    showWarning = false
                    // Start the game using THIS game area's real size, so
                    // hit-testing and rendering share one coordinate space.
                    engine.startGame(
                        requiredKills: effectiveRequiredKills,
                        difficulty: alarm.difficulty,
                        screenSize: geo.size
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Fire Button

    private var fireButton: some View {
        VStack(spacing: 8) {
            Button {
                handleFire()
            } label: {
                ZStack {
                    // Button background (large tappable area)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cyan.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.cyan, lineWidth: 2)
                        )
                        .frame(height: 80)

                    // Button label
                    VStack(spacing: 4) {
                        Image(systemName: "scope")
                            .font(.title)
                        Text("FIRE")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(engine.shotCooldownActive ? .white.opacity(0.5) : .white)
                }
            }
            .buttonStyle(.plain)
            .disabled(engine.isMissionComplete)
            .accessibilityLabel("Fire. Tap when alien overlaps the targeting reticle.")
            .accessibilityHint("Tap to shoot at aliens. You must tap for each shot.")

            // Cooldown indicator
            Text(engine.shotCooldownActive ? "COOLDOWN" : "TAP TO FIRE")
                .font(.caption)
                .foregroundColor(engine.shotCooldownActive ? .red.opacity(0.6) : .white.opacity(0.5))
        }
        .contentShape(Rectangle())
        // Make entire bottom area tappable
        .onTapGesture {
            handleFire()
        }
    }

    // MARK: - Fire Logic

    private func handleFire() {
        let result = engine.fire()

        switch result {
        case .hit:
            HapticManager.shared.shotHit()
            AudioManager.shared.playEffect(.fire)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AudioManager.shared.playEffect(.explosion)
            }

        case .miss:
            HapticManager.shared.shotMiss()
            AudioManager.shared.playEffect(.miss)

        case .cooldown:
            // Brief haptic to indicate cooldown
            HapticManager.shared.shotMiss()
        }
    }

    // MARK: - Completion

    private func handleCompletion() {
        // Stop alarm
        AudioManager.shared.stopAlarm()
        HapticManager.shared.missionComplete()
        AudioManager.shared.playEffect(.success)

        let result = GameResult(
            alarmID: alarm.id,
            requiredKills: effectiveRequiredKills,
            kills: engine.kills,
            misses: engine.misses,
            duration: engine.elapsedTime,
            accuracy: engine.accuracy,
            completedAt: Date()
        )
        completionResult = result
        showCompletion = true
    }

    // MARK: - Emergency Exit

    private var emergencyExit: some View {
        VStack {
            HStack {
                Spacer()
                emergencyExitButton
                    .padding(12)
            }
            Spacer()
        }
    }

    private var emergencyExitButton: some View {
        let isEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.emergencyExitEnabled) as? Bool ?? true

        guard isEnabled else {
            return AnyView(EmptyView())
        }

        return AnyView(
            Button {
                // No tap action — requires long press
            } label: {
                Text("🚨 Emergency Exit")
                    .font(.caption2)
                    .foregroundColor(.red.opacity(0.5))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(emergencyHoldProgress * 0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 5.0)
                    .onChanged { _ in
                        // Track progress
                    }
                    .onEnded { _ in
                        showEmergencyConfirm = true
                    }
            )
            .alert("Emergency Exit", isPresented: $showEmergencyConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Dismiss Alarm", role: .destructive) {
                    performEmergencyExit()
                }
            } message: {
                Text("This will dismiss the current alarm without completing the challenge.\n\nThis occurrence will be recorded as \"Emergency Dismissed.\"")
            }
        )
    }

    private func performEmergencyExit() {
        engine.stopGame()
        AudioManager.shared.stopAlarm()
        AlarmScheduler.shared.dismissActiveAlarm()

        let result = GameResult(
            alarmID: alarm.id,
            requiredKills: effectiveRequiredKills,
            kills: engine.kills,
            misses: engine.misses,
            duration: engine.elapsedTime,
            accuracy: engine.accuracy,
            completedAt: Date(),
            isEmergencyExit: true
        )
        completionResult = result
        showCompletion = true
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Game Result

struct GameResult {
    let alarmID: UUID
    let requiredKills: Int
    let kills: Int
    let misses: Int
    let duration: TimeInterval
    let accuracy: Double
    let completedAt: Date
    var isEmergencyExit: Bool = false
}

/// Pre-game warning overlay — flashes the objective before the first alien.
struct WarningOverlay: View {
    let requiredKills: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("⚠️")
                    .font(.system(size: 64))

                Text("WAKE-UP MISSION")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)

                Text("Destroy at least \(requiredKills) aliens to turn off the alarm.")
                    .font(.system(size: 19, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text("Hit the target to lock in each kill. The alarm will not\nturn off until the goal is reached.")
                    .font(.system(size: 17))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)

                Text("GET READY…")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
        }
    }
}