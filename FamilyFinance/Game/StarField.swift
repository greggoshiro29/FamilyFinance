import SwiftUI

/// Animated star field background for the game.
struct StarField: View {
    @State private var stars: [Star] = []
    @State private var timer: Timer?
    @State private var screenSize: CGSize = .zero

    let starCount: Int = 60

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for star in stars {
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: star.position.x,
                            y: star.position.y,
                            width: star.size,
                            height: star.size
                        )),
                        with: .color(.white.opacity(star.opacity))
                    )
                }
            }
            .onAppear {
                screenSize = geometry.size
                generateStars()
                timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
                    Task { @MainActor in
                        updateStars()
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    private func generateStars() {
        let w = screenSize.width > 0 ? screenSize.width : 400
        let h = screenSize.height > 0 ? screenSize.height : 800
        stars = (0..<starCount).map { _ in
            Star(
                position: CGPoint(
                    x: CGFloat.random(in: 0...w),
                    y: CGFloat.random(in: 0...h)
                ),
                speed: CGFloat.random(in: 20...60),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...0.9)
            )
        }
    }

    private func updateStars() {
        let h = screenSize.height > 0 ? screenSize.height : 800
        let w = screenSize.width > 0 ? screenSize.width : 400
        for i in 0..<stars.count {
            stars[i].position.y += stars[i].speed / 60.0
            if stars[i].position.y > h {
                stars[i].position.y = -5
                stars[i].position.x = CGFloat.random(in: 0...w)
            }
        }
    }
}

private struct Star: Identifiable {
    let id = UUID()
    var position: CGPoint
    let speed: CGFloat
    let size: CGFloat
    let opacity: Double
}