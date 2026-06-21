import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var settings: PracticeSettings
    @StateObject private var viewModel = PracticePlayerViewModel()
    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false

    private var session: MeditationSession { settings.session }

    var body: some View {
        NavigationStack {
            ZStack {
                MoodAnimationView().ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 0)
                    controls
                        .padding(.horizontal, 22)
                        .padding(.top, 18)
                        .padding(.bottom, 18)
                        .background(
                            LinearGradient(colors: [.clear, Theme.auraBottom.opacity(0.85)],
                                           startPoint: .top, endPoint: .bottom)
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
            }
            .toolbar { topNav }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { reloadAudio(); applyMusic() }
        .onChange(of: settings.sessionId) { _, _ in reloadAudio() }
        .onChange(of: settings.voiceId) { _, _ in reloadAudio() }
        .onChange(of: settings.sessionLength) { _, new in viewModel.setPreferredLength(new) }
        .onChange(of: settings.musicEnabled) { _, _ in applyMusic() }
        .onChange(of: settings.musicPersistentID) { _, _ in applyMusic() }
        .onChange(of: settings.musicVolume) { _, new in viewModel.setMusicVolume(new) }
        .onChange(of: viewModel.currentTime) { _, newValue in
            guard !isScrubbing else { return }
            scrubValue = newValue
        }
    }

    // MARK: - Top navigation (session • length • music toggle)

    @ToolbarContentBuilder
    private var topNav: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Session", selection: $settings.sessionId) {
                    ForEach(Catalog.sessions) { s in
                        Text("\(s.title) · \(s.subtitle)").tag(s.id)
                    }
                }
            } label: {
                Label(session.title, systemImage: "square.stack.3d.up.fill")
                    .font(.system(.subheadline, design: .rounded))
                    .lineLimit(1)
            }
            .tint(Theme.ink)
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            lengthControl
            Button {
                settings.musicEnabled.toggle()
            } label: {
                Image(systemName: settings.musicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .tint(settings.musicEnabled ? Theme.accent : Theme.mutedInk)
            .accessibilityLabel(settings.musicEnabled ? "Background music on" : "Background music off")
        }
    }

    @ViewBuilder
    private var lengthControl: some View {
        if case .flexible(let options) = session.lengthMode {
            Menu {
                Picker("Length", selection: $settings.sessionLength) {
                    ForEach(options, id: \.self) { opt in
                        Text("\(Int(opt / 60)) min").tag(opt)
                    }
                }
            } label: {
                Label("\(Int(viewModel.sessionLength / 60)) min", systemImage: "timer")
                    .font(.system(.subheadline, design: .rounded))
            }
            .tint(Theme.ink)
        } else {
            Label("\(Int((viewModel.sessionLength / 60).rounded())) min", systemImage: "timer")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.mutedInk)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.system(size: 33, weight: .regular, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .foregroundStyle(Theme.ink)
            Text(session.subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.mutedInk)
        }
        .shadow(color: .black.opacity(0.35), radius: 10, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Transport

    private var controls: some View {
        VStack(spacing: 18) {
            if viewModel.audioMissing {
                Text("This voice isn’t available for this session yet.")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedInk)
                    .multilineTextAlignment(.center)
            }
            if settings.musicEnabled, settings.musicTitle == nil {
                Text("Choose a song in Settings to play under your practice.")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedInk)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 14) {
                Text(timeString(viewModel.currentTime))
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 58, alignment: .leading)

                Slider(value: $scrubValue, in: 0...max(viewModel.sessionLength, 1),
                       onEditingChanged: { editing in
                           isScrubbing = editing
                           if !editing { viewModel.seek(to: scrubValue) }
                       })
                    .tint(Theme.progress)

                Text("-\(timeString(max(viewModel.sessionLength - viewModel.currentTime, 0)))")
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 68, alignment: .trailing)
            }

            HStack(spacing: 28) {
                controlButton(title: "Start", systemImage: "play.fill") { viewModel.start() }
                    .disabled(viewModel.audioMissing)
                controlButton(title: "Pause", systemImage: "pause.fill") { viewModel.pause() }
                    .opacity(viewModel.isPlaying ? 1 : 0.72)
                controlButton(title: "Stop", systemImage: "stop.fill") { viewModel.stop() }
            }
        }
    }

    // MARK: - Wiring

    private func reloadAudio() {
        viewModel.load(session: settings.session, voice: settings.voice,
                       preferredLength: settings.sessionLength)
        applyMusic()
    }

    private func applyMusic() {
        viewModel.applyMusic(enabled: settings.musicEnabled, volume: settings.musicVolume,
                             title: settings.musicTitle, persistentID: settings.musicPersistentID)
    }

    private func controlButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 62, height: 62)
                    .background(Theme.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.mutedInk)
            }
            .frame(minWidth: 76)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.control)
        .accessibilityLabel(title)
    }

    private func timeString(_ seconds: Double) -> String {
        let total = max(Int(seconds.rounded(.down)), 0)
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }
}

#Preview {
    PracticeView().environmentObject(PracticeSettings())
}
