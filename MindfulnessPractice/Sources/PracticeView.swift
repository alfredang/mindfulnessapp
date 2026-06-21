import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticePlayerViewModel()
    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false
    @State private var showingMusicPicker = false

    var body: some View {
        ZStack {
            ZenAnimationView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 0)

                controls
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                    .background(
                        LinearGradient(
                            colors: [.clear, Theme.auraBottom.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
        .onChange(of: viewModel.currentTime) { _, newValue in
            guard !isScrubbing else { return }
            scrubValue = newValue
        }
        .sheet(isPresented: $showingMusicPicker) {
            MusicPicker { title, url in
                viewModel.setBackgroundMusic(title: title, url: url)
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mindfulness Practice")
                .font(.system(size: 33, weight: .regular, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .foregroundStyle(Theme.ink)
            Text("Breathe with the light")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.mutedInk)
        }
        .shadow(color: .black.opacity(0.35), radius: 10, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private var controls: some View {
        VStack(spacing: 18) {
            optionsRow

            HStack(spacing: 14) {
                Text(timeString(viewModel.currentTime))
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 58, alignment: .leading)

                Slider(
                    value: $scrubValue,
                    in: 0...max(viewModel.sessionLength, 1),
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if !editing { viewModel.seek(to: scrubValue) }
                    }
                )
                .tint(Theme.progress)

                Text("-\(timeString(max(viewModel.sessionLength - viewModel.currentTime, 0)))")
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 68, alignment: .trailing)
            }

            HStack(spacing: 28) {
                controlButton(title: "Start", systemImage: "play.fill") { viewModel.start() }
                controlButton(title: "Pause", systemImage: "pause.fill") { viewModel.pause() }
                    .opacity(viewModel.isPlaying ? 1 : 0.72)
                controlButton(title: "Stop", systemImage: "stop.fill") { viewModel.stop() }
            }
        }
    }

    private var optionsRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(viewModel.lengthOptions, id: \.self) { option in
                        Button {
                            viewModel.setSessionLength(option)
                        } label: {
                            Label("\(Int(option / 60)) min",
                                  systemImage: viewModel.sessionLength == option ? "checkmark" : "")
                        }
                    }
                } label: {
                    pill(icon: "timer", text: "\(Int(viewModel.sessionLength / 60)) min")
                }

                Button { showingMusicPicker = true } label: {
                    pill(icon: "music.note",
                         text: viewModel.musicTitle ?? "Background Music",
                         trailing: viewModel.musicTitle != nil ? "xmark.circle.fill" : nil)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    // Tapping the little "x" clears the current track instead of opening the picker.
                    if viewModel.musicTitle != nil { viewModel.clearBackgroundMusic() }
                    else { showingMusicPicker = true }
                })
            }

            if let musicError = viewModel.musicError {
                Text(musicError)
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedInk)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func pill(icon: String, text: String, trailing: String? = nil) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(text).lineLimit(1)
            if let trailing { Image(systemName: trailing) }
        }
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
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
    PracticeView()
}
