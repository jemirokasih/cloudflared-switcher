import SwiftUI
import AppKit

struct LogsView: View {
    @ObservedObject var tunnelManager: TunnelManager
    @State private var isExpanded: Bool = false
    @State private var isCopiedFeedback: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("Terminal Logs (\(tunnelManager.logs.count))")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()

                    if isExpanded {
                        Button(action: copyLogs) {
                            HStack(spacing: 3) {
                                Image(systemName: isCopiedFeedback ? "checkmark" : "doc.on.doc")
                                Text(isCopiedFeedback ? "Copied!" : "Copy")
                            }
                            .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)

                        Button(action: {
                            tunnelManager.clearLogs()
                        }) {
                            Text("Clear")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 3) {
                            if tunnelManager.logs.isEmpty {
                                Text("No active logs.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(8)
                            } else {
                                ForEach(Array(tunnelManager.logs.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(logColor(for: log))
                                        .textSelection(.enabled)
                                        .id(index)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                    }
                    .frame(height: 140)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: tunnelManager.logs.count) { _ in
                        if let lastIndex = tunnelManager.logs.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    private func copyLogs() {
        let combined = tunnelManager.logs.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(combined, forType: .string)

        isCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopiedFeedback = false
        }
    }

    private func logColor(for log: String) -> Color {
        let lower = log.lowercased()
        if lower.contains("error") || lower.contains("❌") || lower.contains("fail") {
            return .red
        } else if lower.contains("✅") || lower.contains("registered") {
            return .green
        } else if lower.contains("🚀") || lower.contains("starting") {
            return .cyan
        } else if lower.contains("🛑") || lower.contains("stopping") {
            return .orange
        }
        return .primary.opacity(0.85)
    }
}
