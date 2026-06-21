import SwiftUI

/// Root bottom-tab navigation: the practice screen plus Feedback and About.
struct MainTabView: View {
    var body: some View {
        TabView {
            PracticeView()
                .tabItem { Label("Practice", systemImage: "leaf.fill") }

            FeedbackView()
                .tabItem { Label("Feedback", systemImage: "bubble.left.and.bubble.right.fill") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle.fill") }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
