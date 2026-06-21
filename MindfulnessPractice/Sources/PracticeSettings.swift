import Foundation

/// User choices that persist across launches (session, voice, length, and the
/// background-music selection / volume). Backed by `UserDefaults`.
@MainActor
final class PracticeSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var sessionId: String { didSet { defaults.set(sessionId, forKey: K.session) } }
    @Published var voiceId: String { didSet { defaults.set(voiceId, forKey: K.voice) } }
    /// Chosen length (seconds) for the flexible session.
    @Published var sessionLength: Double { didSet { defaults.set(sessionLength, forKey: K.length) } }

    @Published var musicEnabled: Bool { didSet { defaults.set(musicEnabled, forKey: K.musicOn) } }
    /// 0...1 — scales the (already quiet) background-music level. Default 0.5.
    @Published var musicVolume: Double { didSet { defaults.set(musicVolume, forKey: K.musicVol) } }
    @Published var musicTitle: String? { didSet { defaults.set(musicTitle, forKey: K.musicTitle) } }
    /// Persistent id of the chosen `MPMediaItem`, so the song survives relaunch.
    @Published var musicPersistentID: UInt64 { didSet { defaults.set(String(musicPersistentID), forKey: K.musicID) } }

    var session: MeditationSession { Catalog.session(sessionId) }
    var voice: Voice { Catalog.voice(voiceId) }

    init() {
        sessionId = defaults.string(forKey: K.session) ?? Catalog.sessions[0].id
        voiceId = defaults.string(forKey: K.voice) ?? Catalog.voices[0].id
        let storedLen = defaults.double(forKey: K.length)
        sessionLength = storedLen > 0 ? storedLen : 10 * 60
        musicEnabled = defaults.bool(forKey: K.musicOn)
        let storedVol = defaults.object(forKey: K.musicVol) as? Double
        musicVolume = storedVol ?? 0.5
        musicTitle = defaults.string(forKey: K.musicTitle)
        musicPersistentID = UInt64(defaults.string(forKey: K.musicID) ?? "") ?? 0
    }

    func clearMusic() {
        musicTitle = nil
        musicPersistentID = 0
    }

    private enum K {
        static let session = "pref.sessionId"
        static let voice = "pref.voiceId"
        static let length = "pref.sessionLength"
        static let musicOn = "pref.musicEnabled"
        static let musicVol = "pref.musicVolume"
        static let musicTitle = "pref.musicTitle"
        static let musicID = "pref.musicPersistentID"
    }
}
