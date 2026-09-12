import SwiftUI

/// Targeting reticle drawn at the center of the game screen.
struct TargetingReticle: View {
    let size: CGFloat
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.cyan.opacity(0.8), lineWidth: 3)
                .frame(width: size, height: size)

            // Inner ring
            Circle()
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                .frame(width: size * 0.65, height: size * 0.65)

            // Crosshair lines
            Rectangle()
                .fill(Color.cyan.opacity(0.6))
                .frame(width: size * 0.8, height: 1)

            Rectangle()
                .fill(Color.cyan.opacity(0.6))
                .frame(width: 1, height: size * 0.8)

            // Center dot
            Circle()
                .fill(Color.cyan)
                .frame(width: 5, height: 5)

            // Rotating tick marks (outer)
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.cyan.opacity(0.4))
                    .frame(width: 8, height: 2)
                    .offset(y: -size/2 - 4)
                    .rotationEffect(.degrees(Double(i) * 90 + rotation))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}