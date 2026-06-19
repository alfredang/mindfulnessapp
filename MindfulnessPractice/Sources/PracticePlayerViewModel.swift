import AVFoundation
import Combine
import Foundation

@MainActor
final class PracticePlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 509.37

    let player: AVPlayer

    nonisolated(unsafe) private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let bundledAudio = Bundle.main.url(forResource: "MindfulnessPractice", withExtension: "m4a")
        let folderAudio = Bundle.main.url(forResource: "MindfulnessPractice", withExtension: "m4a", subdirectory: "Resources")

        guard let url = bundledAudio ?? folderAudio else {
            fatalError("MindfulnessPractice.m4a is missing from the app bundle.")
        }

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .pause

        configureAudio()
        observePlayer(item: item)
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    func start() {
        if currentTime >= duration - 0.5 {
            seek(to: 0)
        }

        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func stop() {
        player.pause()
        seek(to: 0)
        isPlaying = false
    }

    func seek(to seconds: Double) {
        let clampedSeconds = min(max(seconds, 0), duration)
        player.seek(to: CMTime(seconds: clampedSeconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clampedSeconds
    }

    private func configureAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            assertionFailure("Audio session setup failed: \(error)")
        }
    }

    private func observePlayer(item: AVPlayerItem) {
        Task {
            let loadedDuration = try? await item.asset.load(.duration)
            if let seconds = loadedDuration?.seconds, seconds.isFinite {
                duration = seconds
            }
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
            }
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaying = false
                self?.seek(to: self?.duration ?? 0)
            }
            .store(in: &cancellables)
    }
}
