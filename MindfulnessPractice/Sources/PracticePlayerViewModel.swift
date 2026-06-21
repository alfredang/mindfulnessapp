import AVFoundation
import Foundation

/// Drives playback for the currently-selected session + voice.
///
/// Playback is scheduled on the audio-device clock (`play(atTime:)`) rather than a
/// `Timer`, so the experience keeps running unbroken when the phone locks or the
/// app is suspended — including the closing "wake-up" of a flexible session, which
/// is scheduled to land exactly at the chosen length. The `Timer` only updates the
/// on-screen scrubber while the app is in the foreground.
@MainActor
final class PracticePlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published private(set) var sessionLength: Double = 0
    @Published var audioMissing = false
    @Published var musicError: String?

    private var introPlayer: AVAudioPlayer?   // intro clip (flexible) or the whole clip (fixed)
    private var outroPlayer: AVAudioPlayer?   // closing wake-up clip (flexible only)
    private var musicPlayer: AVAudioPlayer?
    private var introDuration: Double = 0
    private var outroDuration: Double = 0

    private var session = Catalog.sessions[0]
    private var preferredLength: Double = 10 * 60
    private var musicEnabledPref = false
    private var musicVolumePref = 0.5

    private var ticker: Timer?
    private var anchorDate: Date?
    private var anchorElapsed: Double = 0

    private let minGap: Double = 30        // shortest mid-session silence we allow

    init() {
        configureAudioSession()
        registerForInterruptions()
    }

    // MARK: - Configuration (driven by PracticeSettings via the View)

    /// Load the audio for a session + voice. Stops any current playback.
    func load(session: MeditationSession, voice: Voice, preferredLength: Double) {
        stop()
        self.session = session
        self.preferredLength = preferredLength

        introPlayer = makePlayer(named: session.introResource(for: voice))
        introDuration = introPlayer?.duration ?? 0

        if let outroName = session.outroResource(for: voice) {
            outroPlayer = makePlayer(named: outroName)
            outroDuration = outroPlayer?.duration ?? 0
        } else {
            outroPlayer = nil
            outroDuration = 0
        }

        audioMissing = (introPlayer == nil)
        recomputeSessionLength()
        currentTime = 0
    }

    func setPreferredLength(_ length: Double) {
        preferredLength = length
        recomputeSessionLength()
        if currentTime > sessionLength { seek(to: sessionLength) }
    }

    // MARK: - Background music

    func applyMusic(enabled: Bool, volume: Double, title: String?, persistentID: UInt64) {
        musicEnabledPref = enabled
        musicVolumePref = volume

        if enabled, let title, persistentID != 0 {
            if musicPlayer == nil {
                loadMusic(title: title, persistentID: persistentID)
            }
            musicPlayer?.volume = musicLevel
            if isPlaying, musicPlayer?.isPlaying == false { musicPlayer?.play() }
        } else {
            musicPlayer?.stop()
            musicPlayer = nil
        }
    }

    func setMusicVolume(_ volume: Double) {
        musicVolumePref = volume
        musicPlayer?.volume = musicLevel
    }

    /// Background music sits gently beneath the voice: a 0...1 user setting scaled
    /// into a quiet ceiling so it never overpowers the narration.
    private var musicLevel: Float { Float(musicVolumePref) * 0.45 }

    private func loadMusic(title: String, persistentID: UInt64) {
        guard let url = MusicLibrary.assetURL(forPersistentID: persistentID) else {
            musicError = "“\(title)” can’t be played — choose a song downloaded to this device."
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = musicLevel
            player.prepareToPlay()
            musicPlayer = player
            musicError = nil
        } catch {
            musicError = "Couldn’t play “\(title)”."
        }
    }

    // MARK: - Transport

    func start() {
        guard introPlayer != nil else { return }
        if currentTime >= sessionLength - 0.3 { currentTime = 0 }
        schedule(from: currentTime)
        isPlaying = true
        startTicker()
    }

    func pause() {
        guard isPlaying else { return }
        currentTime = clampedNow()
        introPlayer?.pause()
        outroPlayer?.pause()
        musicPlayer?.pause()
        isPlaying = false
        ticker?.invalidate()
    }

    func stop() {
        introPlayer?.stop()
        outroPlayer?.stop()
        musicPlayer?.stop()
        introPlayer?.currentTime = 0
        outroPlayer?.currentTime = 0
        ticker?.invalidate()
        isPlaying = false
        currentTime = 0
        anchorDate = nil
    }

    func seek(to seconds: Double) {
        let clamped = min(max(seconds, 0), sessionLength)
        currentTime = clamped
        if isPlaying {
            introPlayer?.pause()
            outroPlayer?.pause()
            schedule(from: clamped)
        }
    }

    // MARK: - Scheduling

    /// Schedule both clips (and music) on the shared device clock so playback is
    /// driven by hardware time — robust to the app being suspended in the background.
    private func schedule(from t: Double) {
        guard let intro = introPlayer else { return }
        let base = intro.deviceCurrentTime + 0.2
        let outroStart = sessionLength - outroDuration

        // Voice
        if outroPlayer == nil {
            // Fixed session: one clip spans the whole session.
            intro.currentTime = min(t, max(intro.duration - 0.05, 0))
            intro.play(atTime: base)
        } else {
            if t < introDuration {
                intro.currentTime = t
                intro.play(atTime: base)
            }
            if let outro = outroPlayer {
                if t <= outroStart {
                    outro.currentTime = 0
                    outro.play(atTime: base + (outroStart - t))
                } else {
                    outro.currentTime = min(t - outroStart, max(outro.duration - 0.05, 0))
                    outro.play(atTime: base)
                }
            }
        }

        // Music: loop enough to cover the remaining session, then fall silent.
        if let music = musicPlayer {
            let remaining = max(sessionLength - t, 0)
            let unit = max(music.duration, 1)
            music.numberOfLoops = remaining > unit ? Int(ceil(remaining / unit)) : 0
            music.currentTime = 0
            music.play(atTime: base)
        }

        anchorElapsed = t
        anchorDate = Date().addingTimeInterval(0.2)
    }

    // MARK: - Internals

    private func recomputeSessionLength() {
        switch session.lengthMode {
        case .fixed:
            sessionLength = max(introDuration, 1)
        case .flexible:
            let floorLen = introDuration + outroDuration + minGap
            sessionLength = max(preferredLength, floorLen)
        }
    }

    private func makePlayer(named name: String) -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: name, withExtension: "m4a")
            ?? Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "audio")
        guard let url else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    private func clampedNow() -> Double {
        guard let anchorDate else { return currentTime }
        return min(anchorElapsed + Date().timeIntervalSince(anchorDate), sessionLength)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            assertionFailure("Audio session setup failed: \(error)")
        }
    }

    private func registerForInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            // Extract Sendable primitives before hopping onto the main actor.
            let info = note.userInfo
            let typeRaw = info?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionRaw = info?[AVAudioSessionInterruptionOptionKey] as? UInt
            MainActor.assumeIsolated {
                self?.handleInterruption(typeRaw: typeRaw, optionRaw: optionRaw)
            }
        }
    }

    private func handleInterruption(typeRaw: UInt?, optionRaw: UInt?) {
        guard let typeRaw, let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
        switch type {
        case .began:
            if isPlaying { pause() }
        case .ended:
            let opts = optionRaw.map { AVAudioSession.InterruptionOptions(rawValue: $0) }
            if opts?.contains(.shouldResume) == true { start() }
        @unknown default:
            break
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard isPlaying else { return }
        currentTime = clampedNow()
        if currentTime >= sessionLength - 0.05 { stop() }
    }
}
