import Foundation
import AVFoundation

/// Manages alarm audio playback with proper AVAudioSession handling.
/// Generates synthesized alarm sounds instead of requiring bundled audio files.
@MainActor
final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    @Published var isPlaying = false

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var currentBuffer: AVAudioPCMBuffer?
    private var currentFormat: AVAudioFormat?
    private var timer: Timer?

    /// Holds transient one-shot effect engines so they aren't deallocated
    /// before their buffer finishes (local-variable engines go silent).
    private var effectEngines: [AVAudioEngine] = []

    private override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch {
            print("AudioManager: Failed to set audio session category: \(error)")
        }
    }

    /// Start playing the selected alarm sound in a loop
    func startAlarm(sound: AlarmSound) {
        stopAlarm()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()

            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)

            let (buffer, format) = generateAlarmBuffer(for: sound)

            engine.prepare()
            try engine.start()

            // Loop playback
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()

            self.audioEngine = engine
            self.playerNode = player
            self.currentBuffer = buffer
            self.currentFormat = format
            self.isPlaying = true

        } catch {
            print("AudioManager: Failed to start alarm: \(error)")
        }
    }

    /// Stop all alarm audio
    func stopAlarm() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        currentBuffer = nil
        currentFormat = nil
        isPlaying = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioManager: Failed to deactivate session: \(error)")
        }
    }

    /// Play a short sound effect (fire/explosion)
    func playEffect(_ effect: GameSoundEffect) {
        guard let (buffer, _) = generateEffectBuffer(for: effect) else { return }

        let tempEngine = AVAudioEngine()
        let tempPlayer = AVAudioPlayerNode()

        tempEngine.attach(tempPlayer)
        tempEngine.connect(tempPlayer, to: tempEngine.mainMixerNode, format: buffer.format)

        do {
            try tempEngine.start()
            tempPlayer.scheduleBuffer(buffer, at: nil)
            tempPlayer.play()

            // Retain the engine so it isn't deallocated before the effect plays.
            effectEngines.append(tempEngine)

            // Auto-stop + release after effect plays
            let duration = Double(buffer.frameLength) / buffer.format.sampleRate
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self, weak tempEngine, weak tempPlayer] in
                tempPlayer?.stop()
                tempEngine?.stop()
                if let tempEngine {
                    self?.effectEngines.removeAll { $0 === tempEngine }
                }
            }
        } catch {
            print("AudioManager: Failed to play effect: \(error)")
        }
    }

    /// Preview a sound briefly (non-looping, for settings)
    func previewAlarm(sound: AlarmSound) {
        stopAlarm()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)

            let (buffer, _) = generateAlarmBuffer(for: sound)
            engine.prepare()
            try engine.start()
            player.scheduleBuffer(buffer, at: nil)
            player.play()

            // Retain engine + player so they aren't deallocated the moment this
            // method returns (the local-variable pattern makes the preview
            // silent). Keep them like startAlarm does, then stop after 2s.
            self.audioEngine = engine
            self.playerNode = player
            self.isPlaying = true

            // Auto-stop after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.stopAlarm()
            }
        } catch {
            print("AudioManager: Failed to preview: \(error)")
        }
    }

    // MARK: - Sound Generation

    private func generateAlarmBuffer(for sound: AlarmSound) -> (AVAudioPCMBuffer, AVAudioFormat) {
        let sampleRate: Double = 44100
        let duration: Double = 1.5 // Loop duration
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            fatalError("Could not create audio buffer")
        }
        buffer.frameLength = frameCount

        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(format.channelCount))
        let frameLength = Int(buffer.frameLength)

        switch sound {
        case .spaceSiren:
            generateSpaceSiren(channels: channels, frameLength: frameLength, sampleRate: sampleRate)
        case .reactorAlert:
            generateReactorAlert(channels: channels, frameLength: frameLength, sampleRate: sampleRate)
        case .commandAlarm:
            generateCommandAlarm(channels: channels, frameLength: frameLength, sampleRate: sampleRate)
        case .alienInvasion:
            generateAlienInvasion(channels: channels, frameLength: frameLength, sampleRate: sampleRate)
        case .emergencyPulse:
            generateEmergencyPulse(channels: channels, frameLength: frameLength, sampleRate: sampleRate)
        }

        return (buffer, format)
    }

    // MARK: - Sound Synthesizers

    private func generateSpaceSiren(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                     frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            let freq = 400 + 600 * sin(2 * .pi * 0.5 * t) // Wobbling siren
            let sample = Float(sin(2 * .pi * freq * t) * 0.5)
            for ch in 0..<channels.count {
                channels[ch][i] = sample
            }
        }
    }

    private func generateReactorAlert(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                       frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            // Two-tone alternating alert
            let tone = Int(t * 2) % 2 == 0 ? 800.0 : 600.0
            let sample = Float(sin(2 * .pi * tone * t) * 0.5)
            for ch in 0..<channels.count {
                channels[ch][i] = sample
            }
        }
    }

    private func generateCommandAlarm(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                       frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            let freq = 1000 + 200 * sin(2 * .pi * 3 * t) // Rapid warble
            let sample = Float(sin(2 * .pi * freq * t) * 0.5)
            for ch in 0..<channels.count {
                channels[ch][i] = sample
            }
        }
    }

    private func generateAlienInvasion(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                        frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            // Descending tone sequence
            let phase = Int(t * 3) % 4
            let freq: Double = [1200, 900, 700, 500][phase]
            let sample = Float(sin(2 * .pi * freq * t) * 0.5)
            for ch in 0..<channels.count {
                channels[ch][i] = sample
            }
        }
    }

    private func generateEmergencyPulse(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                         frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            // Pulsing beep
            let pulse = sin(2 * .pi * 2 * t) > 0 ? 1.0 : 0.2
            let sample = Float(sin(2 * .pi * 880 * t) * pulse * 0.5)
            for ch in 0..<channels.count {
                channels[ch][i] = sample
            }
        }
    }

    // MARK: - Sound Effects

    private func generateEffectBuffer(for effect: GameSoundEffect) -> (AVAudioPCMBuffer, AVAudioFormat)? {
        let sampleRate: Double = 44100
        let duration: Double = effect.duration
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: 1)

        switch effect {
        case .fire:
            generateFireEffect(channels: channels, frameLength: Int(frameCount), sampleRate: sampleRate)
        case .explosion:
            generateExplosionEffect(channels: channels, frameLength: Int(frameCount), sampleRate: sampleRate)
        case .miss:
            generateMissEffect(channels: channels, frameLength: Int(frameCount), sampleRate: sampleRate)
        case .success:
            generateSuccessEffect(channels: channels, frameLength: Int(frameCount), sampleRate: sampleRate)
        }

        return (buffer, format)
    }

    private func generateFireEffect(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                     frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 20)
            let sample = Float(sin(2 * .pi * 600 * t) * envelope * 0.6)
            channels[0][i] = sample
        }
    }

    private func generateExplosionEffect(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                          frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 8)
            let noise = Double.random(in: -1...1)
            let sample = Float(noise * envelope * 0.7)
            channels[0][i] = sample
        }
    }

    private func generateMissEffect(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                     frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 15)
            let sample = Float(sin(2 * .pi * 200 * t) * envelope * 0.3)
            channels[0][i] = sample
        }
    }

    private func generateSuccessEffect(channels: UnsafeBufferPointer<UnsafeMutablePointer<Float>>,
                                        frameLength: Int, sampleRate: Double) {
        for i in 0..<frameLength {
            let t = Double(i) / sampleRate
            // Rising arpeggio
            let freq = 400 + 300 * min(t / 0.8, 1.0)
            let envelope = exp(-t * 2)
            let sample = Float(sin(2 * .pi * freq * t) * envelope * 0.6)
            channels[0][i] = sample
        }
    }
}

enum GameSoundEffect {
    case fire
    case explosion
    case miss
    case success

    var duration: Double {
        switch self {
        case .fire: return 0.15
        case .explosion: return 0.5
        case .miss: return 0.2
        case .success: return 1.0
        }
    }
}