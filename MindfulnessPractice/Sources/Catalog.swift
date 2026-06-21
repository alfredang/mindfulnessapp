import Foundation

/// How a session's total length is determined.
enum SessionLengthMode: Hashable {
    /// User picks from `options` (seconds); the guided silence scales so the
    /// wake-up always lands at the chosen length. Uses separate intro/outro clips.
    case flexible(options: [Double])
    /// Length is fixed by the recording itself (a single pre-paced clip).
    case fixed
}

/// One guided meditation. Audio is resolved by `<id>-<voiceId>` for fixed
/// sessions, or `<id>-<voiceId>-intro` / `-outro` for flexible ones.
struct MeditationSession: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let lengthMode: SessionLengthMode

    var isSegmented: Bool {
        if case .flexible = lengthMode { return true }
        return false
    }

    func introResource(for voice: Voice) -> String {
        isSegmented ? "\(id)-\(voice.id)-intro" : "\(id)-\(voice.id)"
    }
    func outroResource(for voice: Voice) -> String? {
        isSegmented ? "\(id)-\(voice.id)-outro" : nil
    }
}

/// A narration voice. `id` matches the generated audio-file suffix.
struct Voice: Identifiable, Hashable {
    let id: String
    let label: String
    let language: String
}

enum Catalog {
    static let sessions: [MeditationSession] = [
        MeditationSession(
            id: "original",
            title: "Mindfulness Practice",
            subtitle: "Breathe with the light",
            lengthMode: .flexible(options: [5 * 60, 10 * 60, 15 * 60, 20 * 60])
        ),
        MeditationSession(
            id: "awareness10",
            title: "Awareness of Breath",
            subtitle: "Ten-minute guided practice",
            lengthMode: .fixed
        ),
        MeditationSession(
            id: "awareness5",
            title: "Awareness of Breath",
            subtitle: "Five-minute guided practice",
            lengthMode: .fixed
        ),
    ]

    static let voices: [Voice] = [
        Voice(id: "en-f", label: "English · Female", language: "English"),
        Voice(id: "en-m", label: "English · Male", language: "English"),
        Voice(id: "zh-f", label: "中文 · 女声", language: "中文"),
        Voice(id: "zh-m", label: "中文 · 男声", language: "中文"),
    ]

    static func session(_ id: String) -> MeditationSession {
        sessions.first { $0.id == id } ?? sessions[0]
    }
    static func voice(_ id: String) -> Voice {
        voices.first { $0.id == id } ?? voices[0]
    }
}
