import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.blue)

            VStack(spacing: 4) {
                Text("Cloudflare Switcher")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("A lightweight, on-demand macOS menu bar controller for Cloudflare Tunnel without persistent service daemons.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)

            Divider()

            VStack(spacing: 4) {
                Text("Created by")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Jemiro Kasih")
                    .font(.system(size: 13, weight: .semibold))
            }

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(20)
        .frame(width: 280)
    }
}
