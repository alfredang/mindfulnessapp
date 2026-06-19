import SwiftUI
import UIKit

struct PracticeView: View {
    @StateObject private var viewModel = PracticePlayerViewModel()
    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                practiceImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1180.0 / 1080.0, contentMode: .fit)
                    .clipped()

                Spacer(minLength: 0)

                controls
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
            }
        }
        .onChange(of: viewModel.currentTime) { _, newValue in
            guard !isScrubbing else { return }
            scrubValue = newValue
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    viewModel.stop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 28, weight: .semibold))
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel("Stop practice")

                Spacer()

                Text("NEXT")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .opacity(0.9)
            }

            Text("Awareness of the Breath")
                .font(.system(size: 33, weight: .regular, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(Theme.header)
    }

    private var practiceImage: some View {
        Group {
            if let url = Bundle.main.url(forResource: "practice-zen", withExtension: "jpg"),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Theme.surface)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                Text(timeString(viewModel.currentTime))
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 58, alignment: .leading)

                Slider(
                    value: $scrubValue,
                    in: 0...max(viewModel.duration, 1),
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if !editing {
                            viewModel.seek(to: scrubValue)
                        }
                    }
                )
                .tint(Theme.progress)

                Text("-\(timeString(max(viewModel.duration - viewModel.currentTime, 0)))")
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 68, alignment: .trailing)
            }

            HStack(spacing: 28) {
                controlButton(title: "Start", systemImage: "play.fill") {
                    viewModel.start()
                }

                controlButton(title: "Pause", systemImage: "pause.fill") {
                    viewModel.pause()
                }
                .opacity(viewModel.isPlaying ? 1 : 0.72)

                controlButton(title: "Stop", systemImage: "stop.fill") {
                    viewModel.stop()
                }
            }
        }
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
        let totalSeconds = max(Int(seconds.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):" + String(format: "%02d", seconds)
    }
}

#Preview {
    PracticeView()
}
