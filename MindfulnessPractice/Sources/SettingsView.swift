import SwiftUI

/// Settings tab: choose the narration voice and configure background music.
struct SettingsView: View {
    @EnvironmentObject private var settings: PracticeSettings
    @State private var showingMusicPicker = false
    @State private var musicHint: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Voice") {
                    Picker("Narration voice", selection: $settings.voiceId) {
                        ForEach(Catalog.voices) { voice in
                            Text(voice.label).tag(voice.id)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Toggle("Play background music", isOn: $settings.musicEnabled)

                    Button {
                        showingMusicPicker = true
                    } label: {
                        HStack {
                            Label("Song", systemImage: "music.note")
                            Spacer()
                            Text(settings.musicTitle ?? "Choose…")
                                .foregroundStyle(Theme.mutedInk)
                                .lineLimit(1)
                        }
                    }

                    if settings.musicTitle != nil {
                        Button(role: .destructive) {
                            settings.clearMusic()
                        } label: {
                            Label("Remove song", systemImage: "xmark.circle")
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "speaker.fill").foregroundStyle(Theme.mutedInk)
                            Slider(value: $settings.musicVolume, in: 0...1)
                                .tint(Theme.accent)
                            Image(systemName: "speaker.wave.3.fill").foregroundStyle(Theme.mutedInk)
                        }
                        Text("Volume \(Int(settings.musicVolume * 100))%")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedInk)
                    }
                } header: {
                    Text("Background music")
                } footer: {
                    if let musicHint {
                        Text(musicHint)
                    } else {
                        Text("Music loops gently beneath the narration during your practice.")
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showingMusicPicker) {
            MusicPicker { title, persistentID, url in
                if url == nil {
                    musicHint = "“\(title)” can’t be used — pick a song downloaded to this device."
                } else {
                    musicHint = nil
                    settings.musicTitle = title
                    settings.musicPersistentID = persistentID
                    settings.musicEnabled = true
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SettingsView().environmentObject(PracticeSettings())
}
