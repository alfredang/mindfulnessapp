import SwiftUI
import MediaPlayer

/// Wraps `MPMediaPickerController` so the user can pick background music from their
/// own Music library. Returns the chosen item's playable file URL (nil for tracks with
/// no local/owned asset, e.g. DRM-protected Apple Music that hasn't been downloaded).
struct MusicPicker: UIViewControllerRepresentable {
    var onPick: (_ title: String, _ url: URL?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = true
        picker.prompt = "Choose background music for your session"
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: MPMediaPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: MusicPicker
        init(_ parent: MusicPicker) { self.parent = parent }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems collection: MPMediaItemCollection) {
            let item = collection.items.first
            let title = item?.title ?? "Background music"
            parent.onPick(title, item?.assetURL)
            parent.dismiss()
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            parent.dismiss()
        }
    }
}
