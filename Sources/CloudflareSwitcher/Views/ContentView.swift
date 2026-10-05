import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var tunnelManager = TunnelManager.shared
    @State private var token: String = ""
    @State private var isShowingAbout: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)

                    Text("Cloudflare Switcher")
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                // Status Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(tunnelManager.status.color)
                        .frame(width: 8, height: 8)
                    Text(tunnelManager.status.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(tunnelManager.status.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tunnelManager.status.color.opacity(0.12))
                .cornerRadius(12)
            }

            Divider()

            // Missing binary banner if applicable
            if tunnelManager.status == .missingBinary {
                InstallerBannerView(tunnelManager: tunnelManager)
            }

            // Main Switch Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tunnel Service")
                            .font(.system(size: 13, weight: .semibold))
                        Text(tunnelManager.status.isConnected ? "Tunnel connection is active & forwarding traffic" : "Tunnel connection is inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { tunnelManager.status.isConnected },
                        set: { isTurningOn in
                            if isTurningOn {
                                let activeToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
                                tunnelManager.start(token: activeToken)
                            } else {
                                tunnelManager.stop()
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .disabled(
                        tunnelManager.status.isBusy ||
                        tunnelManager.status == .missingBinary ||
                        token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )

                if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && tunnelManager.status != .missingBinary {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Enter a tunnel token below to enable the switch.")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Token Management Section
            TokenView(currentToken: $token) {
                // Token saved callback
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(10)

            // Live Logs Section
            LogsView(tunnelManager: tunnelManager)

            Divider()

            // Footer
            HStack {
                Button(action: {
                    isShowingAbout = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("About")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
                .sheet(isPresented: $isShowingAbout) {
                    AboutView()
                }

                Spacer()

                if let binPath = tunnelManager.detectedBinaryPath {
                    Text("Bin: \(binPath)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Bin: Not Found")
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                }

                Spacer()

                Button(action: {
                    tunnelManager.forceKillSync()
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 360)
        .onAppear {
            if let saved = TokenStorage.shared.getToken() {
                self.token = saved
            }
            tunnelManager.refreshBinaryStatus()
        }
    }
}
