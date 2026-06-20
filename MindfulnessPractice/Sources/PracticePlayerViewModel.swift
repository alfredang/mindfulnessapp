import AVFoundation
import Foundation

@MainActor
final class PracticePlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    /// Total length of the session the user has chosen (drives the scrubber + auto-stop).
    @Published var sessionLength: Double = 0
    /// Natural length of the guided voice track.
    @Published private(set) var voiceDuration: Double = 0
    /// Title of the chosen background-music track, if any.
    @Published var musicTitle: String?
    @Published var musicError: String?

    /// Length options (seconds) offered in the UI.
    let lengthOptions: [Double] = [5 * 60, 10 * 60, 15 * 60, 20 * 60]

    private let voicePlayer: AVAudioPlayer
    private var musicPlayer: AVAudioPlayer?
    private var ticker: Timer?
    private var anchorDate: Date?      // wall-clock anchor for elapsed time
    private var anchorElapsed: Double = 0

    init() {
        let url = Bundle.main.url(forResource: "MindfulnessPractice", withExtension: "m4a")
            ?? Bundle.main.url(forResource: "MindfulnessPractice", withExtension: "m4a", subdirectory: "Resources")
        guard let url else { fatalError("MindfulnessPractice.m4a is missing from the app bundle.") }

        do {
            voicePlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            fatalError("Could not load guided audio: \(error)")
        }
        voicePlayer.prepareToPlay()
        voiceDuration = voicePlayer.duration
        // Default the session to the option closest to the guided voice length (≈10 min).
        sessionLength = lengthOptions.min(by: { abs($0 - voiceDuration) < abs($1 - voiceDuration) }) ?? voiceDuration
        configureAudioSession()
    }

    // MARK: - Transport

    func start() {
        if currentTime >= sessionLength - 0.3 { seek(to: 0) }
        if currentTime < voiceDuration { voicePlayer.play() }
        musicPlayer?.play()
        isPlaying = true
        anchorElapsed = currentTime
        anchorDate = Date()
        startTicker()
    }

    func pause() {
        voicePlayer.pause()
        musicPlayer?.pause()
        isPlaying = false
        ticker?.invalidate()
    }

    func stop() {
        voicePlayer.pause()
        musicPlayer?.pause()
        ticker?.invalidate()
        seek(to: 0)
        isPlaying = false
    }

    func seek(to seconds: Double) {
        let clamped = min(max(seconds, 0), sessionLength)
        currentTime = clamped
        voicePlayer.currentTime = min(clamped, max(voiceDuration - 0.05, 0))
        anchorElapsed = clamped
        anchorDate = Date()
    }

    func setSessionLength(_ length: Double) {
        sessionLength = length
        if currentTime > length { seek(to: length) }
    }

    // MARK: - Background music

    func setBackgroundMusic(title: String, url: URL?) {
        guard let url else {
            musicError = "“\(title)” can’t be used — pick a song downloaded to this device."
            return
        }
        musicError = nil
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // loop under the whole session
            player.volume = 0.22               // sit gently beneath the voice
            player.prepareToPlay()
            musicPlayer = player
            musicTitle = title
            if isPlaying { player.play() }
        } catch {
            musicError = "Couldn’t play “\(title)”."
        }
    }

    func clearBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        musicTitle = nil
    }

    // MARK: - Internals

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            assertionFailure("Audio session setup failed: \(error)")
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard isPlaying, let anchorDate else { return }
        currentTime = min(anchorElapsed + Date().timeIntervalSince(anchorDate), sessionLength)
        // Voice ends naturally before a longer session; music keeps looping until the end.
        if currentTime >= sessionLength - 0.05 {
            stop()
        }
    }
}
