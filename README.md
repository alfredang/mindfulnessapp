# Mindfulness

A native iOS app for practicing mindfulness — a **"Mindfulness Practice"** session with a calm,
soothing female voice guiding your breath, playing locally on your iPhone. Choose your **session
length**, optionally add **background music from your own library**, and use simple Start / Pause /
Stop controls with a scrubber. No account, no network, no data collection.

![Mindfulness — practice screen](screenshot.png)

## Tech Stack

![iOS](https://img.shields.io/badge/iOS-17.0%2B-black?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0066CC?logo=swift&logoColor=white)
![AVFoundation](https://img.shields.io/badge/AVFoundation-1575F9?logo=apple&logoColor=white)
![XcodeGen](https://img.shields.io/badge/XcodeGen-project.yml-2C3E50)

- **Swift 6 / SwiftUI** — single-screen declarative UI
- **AVFoundation** — `AVAudioPlayer` for the guided voice plus a looping background-music player
- **MediaPlayer** — `MPMediaPickerController` to pick background music from the user's library
- **XcodeGen** — the Xcode project is generated from [`project.yml`](project.yml)
- **GitHub Actions** — auto-build + sign + submit to the App Store on every push to `main`

## Features

- 🧘 Guided **Mindfulness Practice** meditation with a soothing female voice
- ⏱️ **Adjustable session length** — 5 / 10 / 15 / 20 minutes
- 🎵 **Background music** — play a song from your own Music library, gently under the voice
- ▶️ **Start / Pause / Stop** transport with a draggable progress scrubber
- 📱 **iPhone-only**, portrait, fully offline — nothing leaves the device

## Architecture

The app is five Swift files under [`MindfulnessPractice/Sources/`](MindfulnessPractice/Sources/):

| File | Role |
|------|------|
| `MindfulnessPracticeApp.swift` | `@main` entry; one `WindowGroup` → `PracticeView` |
| `PracticeView.swift` | The full UI — title, zen image, length + music pills, scrubber, transport |
| `PracticePlayerViewModel.swift` | `@MainActor` `ObservableObject` — voice `AVAudioPlayer` + looping music player; wall-clock session timer with auto-stop at the chosen length |
| `MusicPicker.swift` | `MPMediaPickerController` wrapper to pick background music from the library |
| `Theme.swift` | Central color palette (dark teal) |

`PracticeView` mirrors the player's `currentTime` into a local scrub value, gated by an
`isScrubbing` flag so dragging the slider doesn't fight live playback updates. All visual
styling flows from `Theme`.

## Build & Run

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) — edit `project.yml`,
never the generated `.pbxproj`.

```bash
xcodegen generate                 # regenerate MindfulnessPractice.xcodeproj
open MindfulnessPractice.xcodeproj # ⌘R in Xcode, or:

xcodebuild -project MindfulnessPractice.xcodeproj \
  -scheme MindfulnessPractice -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

> **Audio:** the guided narration (`MindfulnessPractice.m4a`, ~1.3 MB) is committed. It was
> generated from [`transcript.txt`](MindfulnessPractice/Resources/transcript.txt) with the
> neural on-device TTS [kyutai `pocket-tts`](https://github.com/kyutai-labs/pocket-tts) (female
> voice "anna"), timed to the cue timestamps and slowed + warmed + softened (atempo, EQ, gentle
> reverb) in ffmpeg for a calm, unhurried delivery.

## App Store submission & CI/CD

This repo bundles two project-level skills:
[`app-store-submission`](.claude/skills/app-store-submission/) (archive, sign, upload, and submit
via the ASC API + Xcode CLI) and [`ios-auto-release`](.claude/skills/ios-auto-release/) — a GitHub
Actions pipeline ([`.github/workflows/ios-release.yml`](.github/workflows/ios-release.yml)) that
**auto-builds, signs, uploads, and submits to the App Store on every push to `main`**.

## Acknowledgements

Built by [Tertiary Infotech Academy Pte Ltd](https://www.tertiaryinfotech.com/).
