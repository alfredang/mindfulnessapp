import SwiftUI

/// About tab — app summary, developer (Tertiary Infotech Academy) with a website
/// link, and the build version. Styled to match the app's zen palette.
struct AboutView: View {
    private let developerURL = URL(string: "https://www.tertiaryinfotech.com")!

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("About")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)

                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Mindfulness Practice")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.ink)
                            Text("A quiet space for guided breath meditation. Press play, follow the soothing voice and the gently breathing light, and let each session bring you back to calm — choose your length and add soft background music if you like.")
                                .font(.callout)
                                .foregroundStyle(Theme.mutedInk)
                        }
                    }

                    section("Developer") {
                        card {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 12) {
                                    Image(systemName: "building.2.fill")
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 26)
                                    Text("Tertiary Infotech Academy Pte Ltd")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(Theme.ink)
                                }
                                .padding(.vertical, 14)

                                Divider().overlay(Color.white.opacity(0.12))

                                Link(destination: developerURL) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "globe")
                                            .foregroundStyle(Theme.accent)
                                            .frame(width: 26)
                                        Text("tertiaryinfotech.com")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundStyle(Theme.accent)
                                    }
                                    .padding(.vertical, 14)
                                }
                            }
                        }
                    }

                    section("About") {
                        card {
                            Text("Narration is generated on-device with neural text-to-speech and warmed for calm. No login, no accounts, no data collection — everything plays locally on your iPhone.")
                                .font(.callout)
                                .foregroundStyle(Theme.mutedInk)
                                .padding(.vertical, 2)
                        }
                    }

                    card {
                        HStack {
                            Text("Version")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(versionString)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Theme.mutedInk)
                        }
                    }
                }
                .padding(22)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.mutedInk)
                .padding(.leading, 4)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }
}

#Preview {
    AboutView()
        .preferredColorScheme(.dark)
}
