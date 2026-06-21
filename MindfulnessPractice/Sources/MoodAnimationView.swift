import SwiftUI

/// A calm, generative "aurora" backdrop — overlapping translucent colour fields
/// that slowly drift and breathe, with soft motes rising like incense smoke.
/// Deliberately different from the old concentric-ring look. Pure SwiftUI.
struct MoodAnimationView: View {
    @State private var phase = false

    private let blobs: [Blob] = [
        Blob(color: Theme.glow,   size: 1.15, from: CGPoint(x: -0.25, y: -0.20), to: CGPoint(x: 0.20, y: 0.10), blur: 90, opacity: 0.30),
        Blob(color: Theme.accent, size: 0.95, from: CGPoint(x: 0.30, y: 0.30),  to: CGPoint(x: -0.15, y: -0.10), blur: 80, opacity: 0.24),
        Blob(color: Theme.header, size: 1.30, from: CGPoint(x: 0.10, y: 0.40),  to: CGPoint(x: -0.20, y: 0.05), blur: 110, opacity: 0.40),
    ]

    var body: some View {
        GeometryReader { geo in
            let size = max(min(geo.size.width, geo.size.height), 1)
            ZStack {
                LinearGradient(colors: [Theme.auraTop, Theme.auraBottom],
                               startPoint: .top, endPoint: .bottom)

                ForEach(Array(blobs.enumerated()), id: \.offset) { _, blob in
                    Circle()
                        .fill(blob.color.opacity(blob.opacity))
                        .frame(width: size * blob.size)
                        .blur(radius: blob.blur)
                        .offset(x: size * (phase ? blob.to.x : blob.from.x),
                                y: size * (phase ? blob.to.y : blob.from.y))
                        .scaleEffect(phase ? 1.08 : 0.94)
                }

                MotesView(field: geo.size)

                // Gentle vignette so the glow sits inside the frame.
                RadialGradient(colors: [.clear, Theme.auraBottom.opacity(0.55)],
                               center: .center, startRadius: size * 0.30, endRadius: size * 0.75)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }

    private struct Blob {
        let color: Color
        let size: CGFloat
        let from: CGPoint
        let to: CGPoint
        let blur: CGFloat
        let opacity: Double
    }
}

/// A handful of soft motes that drift slowly upward and fade, looping forever.
private struct MotesView: View {
    let field: CGSize
    private let count = 14

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Mote(seed: i, field: field)
            }
        }
    }
}

private struct Mote: View {
    let seed: Int
    let field: CGSize
    @State private var rise = false

    var body: some View {
        // Deterministic pseudo-random placement from the seed (no Math.random).
        let r = Double((seed * 2654435761) % 1000) / 1000.0
        let r2 = Double((seed * 40503) % 997) / 997.0
        let x = CGFloat(r) * field.width
        let dia = CGFloat(3 + (seed % 4) * 2)
        let duration = 11.0 + r2 * 9.0
        let delay = r * duration

        Circle()
            .fill(Theme.glow.opacity(0.5))
            .frame(width: dia, height: dia)
            .blur(radius: 1.5)
            .position(x: x, y: rise ? -20 : field.height + 20)
            .opacity(rise ? 0.0 : 0.6)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false).delay(delay)) {
                    rise = true
                }
            }
    }
}

#Preview {
    MoodAnimationView()
        .ignoresSafeArea()
}
