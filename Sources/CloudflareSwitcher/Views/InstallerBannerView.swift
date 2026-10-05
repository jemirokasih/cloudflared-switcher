import SwiftUI

struct InstallerBannerView: View {
    @ObservedObject var tunnelManager: TunnelManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
                Text("cloudflared is not installed")
                    .font(.headline)
            }

            Text("The app requires the cloudflared CLI to run tunnels. You can install it automatically using Homebrew.")
                .font(.caption)
                .foregroundColor(.secondary)

            if tunnelManager.isInstallingBinary {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Installing cloudflared...")
                            .font(.caption)
                    }

                    if !tunnelManager.installLogs.isEmpty {
                        ScrollView {
                            Text(tunnelManager.installLogs)
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 70)
                        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                        .cornerRadius(6)
                    }
                }
            } else {
                HStack {
                    Button(action: {
                        tunnelManager.installCloudflared()
                    }) {
                        Label("Install via Homebrew", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Re-check") {
                        tunnelManager.refreshBinaryStatus()
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}
