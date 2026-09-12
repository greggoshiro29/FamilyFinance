import Foundation
import UIKit
import CoreHaptics

/// Manages haptic feedback for alarm, game hits, misses, and completion.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }
        supportsHaptics = true
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
        } catch {
            print("HapticManager: Failed to create engine: \(error)")
            supportsHaptics = false
        }
    }

    // MARK: - Public API

    /// Heavy impact for alarm activation
    func alarmActivated() {
        guard supportsHaptics, let engine = engine else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        playPattern(intensity: 1.0, sharpness: 0.8, duration: 0.5, engine: engine)
    }

    /// Light success tap for a hit
    func shotHit() {
        guard supportsHaptics, let engine = engine else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        playTransient(intensity: 0.7, sharpness: 0.5, engine: engine)
    }

    /// Light error tap for a miss
    func shotMiss() {
        guard supportsHaptics, let engine = engine else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        playTransient(intensity: 0.4, sharpness: 0.2, engine: engine)
    }

    /// Celebratory pattern for mission complete
    func missionComplete() {
        guard supportsHaptics, let engine = engine else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return
        }
        playCelebration(engine: engine)
    }

    private func playTransient(intensity: Float, sharpness: Float, engine: CHHapticEngine) {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Fallback to UIKit haptics
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func playPattern(intensity: Float, sharpness: Float, duration: Double, engine: CHHapticEngine) {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: duration
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    private func playCelebration(engine: CHHapticEngine) {
        var events: [CHHapticEvent] = []
        for i in 0..<4 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 - Float(i) * 0.2)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: Double(i) * 0.2
            )
            events.append(event)
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}