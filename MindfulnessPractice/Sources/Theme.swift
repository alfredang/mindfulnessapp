import SwiftUI

/// Zen palette — soft sage, moss & warm stone. Change the look here, not inline.
enum Theme {
    // Core surfaces
    static let background = Color(red: 0.07, green: 0.12, blue: 0.10)   // deep moss charcoal
    static let header     = Color(red: 0.30, green: 0.42, blue: 0.34)   // muted sage
    static let surface    = Color.white.opacity(0.10)
    static let card       = Color.white.opacity(0.06)

    // Text
    static let ink        = Color.white
    static let mutedInk   = Color.white.opacity(0.70)

    // Controls & accents
    static let control    = Color.white
    static let accent     = Color(red: 0.66, green: 0.78, blue: 0.55)   // soft sage-green accent (links, tab tint)
    static let progress   = Color(red: 0.80, green: 0.84, blue: 0.66)   // warm sand-green
    static let progressTrack = Color.white.opacity(0.14)

    // Animated zen backdrop
    static let auraTop    = Color(red: 0.12, green: 0.20, blue: 0.16)
    static let auraBottom = Color(red: 0.05, green: 0.09, blue: 0.08)
    static let glow       = Color(red: 0.55, green: 0.72, blue: 0.50)   // breathing-orb glow
}
