import SwiftUI

/// Feedback tab — a Title + Message form that opens WhatsApp (web fallback if not
/// installed) to the Tertiary Infotech number with the composed note pre-filled.
struct FeedbackView: View {
    /// Singapore number, country code included, no "+"/spaces — +65 8866 6375.
    private let whatsAppNumber = "6588666375"

    @State private var title = ""
    @State private var message = ""
    @State private var showError = false

    private var canSend: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Feedback")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)

                    Text("Tell us what you love or what we can improve — your note opens in WhatsApp ready to send.")
                        .font(.callout)
                        .foregroundStyle(Theme.mutedInk)

                    fieldLabel("Title")
                    TextField("", text: $title, prompt: Text("A short subject").foregroundStyle(Theme.mutedInk))
                        .textInputAutocapitalization(.sentences)
                        .foregroundStyle(Theme.ink)
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))

                    fieldLabel("Message")
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Share your thoughts…")
                                .foregroundStyle(Theme.mutedInk)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 22)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $message)
                            .foregroundStyle(Theme.ink)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .padding(8)
                    }
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))

                    Button(action: send) {
                        HStack(spacing: 9) {
                            Image(systemName: "paperplane.fill")
                            Text("Send via WhatsApp")
                                .fontWeight(.semibold)
                        }
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.auraBottom)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.accent, in: Capsule())
                        .opacity(canSend ? 1 : 0.5)
                    }
                    .disabled(!canSend)
                    .padding(.top, 6)

                    if showError {
                        Text("Couldn’t open WhatsApp on this device.")
                            .font(.footnote)
                            .foregroundStyle(Theme.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(22)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.mutedInk)
    }

    private func send() {
        var body = ""
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { body += "*\(t)*\n" }
        body += m

        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "wa.me"
        comps.path = "/\(whatsAppNumber)"
        comps.queryItems = [URLQueryItem(name: "text", value: body)]

        guard let url = comps.url else { showError = true; return }
        UIApplication.shared.open(url) { success in
            showError = !success
        }
    }
}

#Preview {
    FeedbackView()
        .preferredColorScheme(.dark)
}
