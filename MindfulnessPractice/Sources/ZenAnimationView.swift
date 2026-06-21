import SwiftUI

/// A calming, generative "zen" backdrop that slowly breathes in and out to gently
/// guide the user's breathing. Pure SwiftUI — no bundled image required.
///
/// Layers (back to front): a soft vertical aura, two drifting glow blobs, a set of
/// concentric breathing rings, and a central breathing orb. Two looping animations
/// drive it — a ~5s breath and a ~18s drift — both eased so nothing ever snaps.
struct ZenAnimationView: View {
    @State private var breathe = false
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let size = max(min(geo.size.width, geo.size.height), 1)
            ZStack {
                LinearGradient(
                    colors: [Theme.auraTop, Theme.auraBottom],
                    startPoint: .top, endPoint: .bottom
                )

                // Slow drifting glow blobs for soft, living depth.
                Circle()
                    .fill(Theme.glow.opacity(0.20))
                    .frame(width: size * 0.95)
                    .blur(radius: 70)
                    .offset(x: drift ? -size * 0.18 : size * 0.16,
                            y: drift ? -size * 0.14 : size * 0.16)

                Circle()
                    .fill(Theme.accent.opacity(0.16))
                    .frame(width: size * 0.75)
                    .blur(radius: 60)
                    .offset(x: drift ? size * 0.20 : -size * 0.16,
                            y: drift ? size * 0.18 : -size * 0.12)

                // Concentric breathing rings.
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(Theme.glow.opacity(0.26 - Double(i) * 0.05), lineWidth: 1.5)
                        .frame(width: size * (0.32 + Double(i) * 0.17))
                        .scaleEffect(breathe ? 1.08 : 0.90)
                }

                // Central breathing orb.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.glow.opacity(0.95), Theme.accent.opacity(0.12)],
                            center: .center, startRadius: 1, endRadius: size * 0.22
                        )
                    )
                    .frame(width: size * 0.34)
                    .blur(radius: 6)
                    .scaleEffect(breathe ? 1.14 : 0.80)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

#Preview {
    ZenAnimationView()
        .background(Theme.background)
        .ignoresSafeArea()
}
