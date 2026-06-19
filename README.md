# Mindfulness

A native iOS app for practicing mindfulness. It guides you through a single
**"Awareness of the Breath"** meditation — a calming spoken session that plays locally on
your iPhone with simple Start / Pause / Stop controls and a scrubber. No account, no network,
no data collection.

![Mindfulness — practice screen](screenshot.png)

## Tech Stack

![iOS](https://img.shields.io/badge/iOS-17.0%2B-black?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0066CC?logo=swift&logoColor=white)
![AVFoundation](https://img.shields.io/badge/AVFoundation-1575F9?logo=apple&logoColor=white)
![XcodeGen](https://img.shields.io/badge/XcodeGen-project.yml-2C3E50)

- **Swift 6 / SwiftUI** — single-screen declarative UI
- **AVFoundation** — `AVPlayer` driving the bundled guided-session track, with a
  `.spokenAudio` audio session that ducks other audio
- **XcodeGen** — the Xcode project is generated from [`project.yml`](project.yml)

## Features

- 🧘 Guided **Awareness of the Breath** meditation (~8.5 min)
- ▶️ **Start / Pause / Stop** transport with a draggable progress scrubber
- 🔊 Spoken-audio session that gently **ducks** music and other apps
- 📱 **iPhone-only**, portrait, fully offline — nothing leaves the device

## Architecture

The app is four Swift files under [`MindfulnessPractice/Sources/`](MindfulnessPractice/Sources/):

| File | Role |
|------|------|
| `MindfulnessPracticeApp.swift` | `@main` entry; one `WindowGroup` → `PracticeView` |
| `PracticeView.swift` | The full UI — header, scenic image, scrubber, transport buttons |
| `PracticePlayerViewModel.swift` | `@MainActor` `ObservableObject` wrapping a single `AVPlayer`; publishes `isPlaying` / `currentTime` / `duration` |
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

> **Note:** the guided-session media track (`MindfulnessPractice.mp4`) is **not** committed —
> it exceeds GitHub's 100 MB file limit and is kept locally. Drop your own
> `MindfulnessPractice/Resources/MindfulnessPractice.mp4` in before building, or wire in your
> own audio source in `PracticePlayerViewModel`.

## App Store submission

This repo bundles the project-level
[`app-store-submission`](.claude/skills/app-store-submission/) skill for archiving, signing,
and submitting the build to App Store Connect via the ASC API + Xcode CLI.

## Acknowledgements

Built by [Tertiary Infotech Academy Pte Ltd](https://www.tertiaryinfotech.com/).
