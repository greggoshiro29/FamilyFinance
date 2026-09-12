import SwiftUI

/// Alien ship views, using the custom "Alien" artwork supplied by the user
/// (Alien.imageset) with per-type color variants.
enum AlienView {
    /// Return the custom artwork asset for a given alien type so each variant
    /// has a distinct look (recolors and a mirrored pose).
    static func assetName(for type: AlienType) -> String {
        switch type {
        case .saucer:  return "Alien"
        case .diamond: return "AlienGreen"
        case .invader: return "AlienCyan"
        case .orb:     return "AlienMagenta"
        case .fighter: return "AlienOrange"
        }
    }

    @ViewBuilder
    static func view(for type: AlienType, size: CGFloat, rotation: CGFloat = 0) -> some View {
        let s = size * type.size
        // Custom alien artwork from the user's image, banked by the current
        // flight direction so it visibly turns as it glides toward the reticle.
        // Multiplier 1.0 keeps the ships ~50% smaller than the original 2.0.
        Image(assetName(for: type))
            .resizable()
            .scaledToFit()
            .frame(width: s, height: s)
            .rotationEffect(.degrees(Double(rotation)))
            .shadow(color: .green.opacity(0.5), radius: 10)
    }
}

/// Particle explosion — a burst of glowing debris flying out from the point
/// of contact (the reticle), fading as they scatter.
struct ExplosionView: View {
    @State private var started = false

    private let particleCount = 36

    var body: some View {
        ZStack {
            // Central white flash
            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .scaleEffect(started ? 0.1 : 1.1)
                .opacity(started ? 0 : 1)

            // Particle burst: each particle flies out along its own angle/
            // distance with a random size, while fading.
            ForEach(0..<particleCount, id: \.self) { i in
                ParticleView(
                    angle: Double(i) / Double(particleCount) * 2 * .pi
                        + Double.random(in: -0.08...0.08),
                    distance: CGFloat.random(in: 30...70),
                    size: CGFloat.random(in: 2.5...7),
                    color: randomParticleColor(),
                    started: started
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                started = true
            }
        }
    }

    private func randomParticleColor() -> Color {
        [Color.yellow, Color.orange, Color.red, Color.white, Color(red: 1.0, green: 0.6, blue: 0.1)]
            .randomElement() ?? .orange
    }
}

/// A single explosion particle that flies outward along a fixed angle and
/// fades out as it travels.
private struct ParticleView: View {
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let color: Color
    var started: Bool = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: started ? CGFloat(cos(angle)) * distance : 0,
                    y: started ? CGFloat(sin(angle)) * distance : 0)
            .scaleEffect(started ? 0.2 : 1)
            .opacity(started ? 0 : 1)
    }
}