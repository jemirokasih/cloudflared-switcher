import SwiftUI

struct TokenView: View {
    @Binding var currentToken: String
    @State private var isShowingPlainToken: Bool = false
    @State private var isSavedFeedback: Bool = false

    var onTokenSaved: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tunnel Token")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if TokenStorage.shared.hasToken {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text(isSavedFeedback ? "Saved!" : "Saved in Keychain")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No token configured")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 6) {
                Group {
                    if isShowingPlainToken {
                        TextField("Paste Cloudflare Tunnel Token...", text: $currentToken)
                    } else {
                        SecureField("Paste Cloudflare Tunnel Token...", text: $currentToken)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))

                Button(action: {
                    isShowingPlainToken.toggle()
                }) {
                    Image(systemName: isShowingPlainToken ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help(isShowingPlainToken ? "Hide Token" : "Show Token")

                Button(action: saveToken) {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(currentToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if TokenStorage.shared.hasToken {
                HStack {
                    Spacer()
                    Button("Remove Token", role: .destructive) {
                        TokenStorage.shared.deleteToken()
                        currentToken = ""
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.8))
                }
            }
        }
    }

    private func saveToken() {
        let trimmed = currentToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            TokenStorage.shared.saveToken(trimmed)
            isSavedFeedback = true
            onTokenSaved()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isSavedFeedback = false
            }
        }
    }
}
