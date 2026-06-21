import SwiftUI

/// Root bottom-tab navigation: the practice screen, Settings, Feedback and About.
struct MainTabView: View {
    @StateObject private var settings = PracticeSettings()

    var body: some View {
        TabView {
            PracticeView()
                .tabItem { Label("Practice", systemImage: "leaf.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }

            FeedbackView()
                .tabItem { Label("Feedback", systemImage: "bubble.left.and.bubble.right.fill") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle.fill") }
        }
        .environmentObject(settings)
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
