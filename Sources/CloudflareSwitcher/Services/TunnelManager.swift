import Foundation
import Combine
import AppKit

/// Pengelola proses tunnel cloudflared, lifecycle, sinyal penghentian, dan stream log
@MainActor
public final class TunnelManager: ObservableObject {
    public static let shared = TunnelManager()

    @Published public private(set) var status: TunnelStatus = .stopped
    @Published public private(set) var logs: [String] = []
    @Published public private(set) var detectedBinaryPath: String?
    @Published public private(set) var isInstallingBinary: Bool = false
    @Published public private(set) var installLogs: String = ""

    private var process: Process?
    private var outputPipe: Pipe?
    private var isUserInitiatedStop: Bool = false
    private let maxLogEntries = 150

    private init() {
        refreshBinaryStatus()
        setupTerminationHook()
    }

    /// Refresh status ketersediaan binary cloudflared
    public func refreshBinaryStatus() {
        let path = BinaryDetector.shared.findCloudflaredPath()
        self.detectedBinaryPath = path
        if path == nil && status == .stopped {
            self.status = .missingBinary
        } else if path != nil && status == .missingBinary {
            self.status = .stopped
        }
    }

    /// Memulai proses tunnel dengan token
    public func start(token: String) {
        guard !status.isBusy && !status.isConnected else { return }

        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            self.status = .error("Tunnel token is empty!")
            return
        }

        refreshBinaryStatus()
        guard let binaryPath = detectedBinaryPath else {
            self.status = .missingBinary
            return
        }

        self.status = .starting
        self.isUserInitiatedStop = false
        self.appendLog("🚀 Running cloudflared tunnel from \(binaryPath)...")

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = [
            "tunnel",
            "--no-autoupdate",
            "run",
            "--token",
            trimmedToken
        ]

        var env = ProcessInfo.processInfo.environment
        let pathEnv = env["PATH"] ?? ""
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + pathEnv
        proc.environment = env

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        self.outputPipe = pipe

        let readHandle = pipe.fileHandleForReading
        readHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }

            Task { @MainActor [weak self] in
                self?.handleProcessOutput(output)
            }
        }

        proc.terminationHandler = { [weak self] terminatedProc in
            Task { @MainActor [weak self] in
                self?.handleProcessTermination(exitCode: terminatedProc.terminationStatus)
            }
        }

        self.process = proc

        do {
            try proc.run()
        } catch {
            self.status = .error("Failed to start process: \(error.localizedDescription)")
            self.appendLog("❌ Error: \(error.localizedDescription)")
            cleanupProcessReferences()
        }
    }

    /// Menghentikan proses tunnel secara graceful
    public func stop() {
        guard let proc = process, proc.isRunning else {
            self.status = .stopped
            cleanupProcessReferences()
            return
        }

        self.isUserInitiatedStop = true
        self.status = .stopping
        self.appendLog("🛑 Stopping tunnel (sending termination signal)...")

        // Mengirim SIGINT agar cloudflared unregister tunnel dengan aman
        proc.interrupt()

        // Fallback: Jika dalam 3 detik belum berhenti, panggil terminate()
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if proc.isRunning {
                proc.terminate()
            }
        }
    }

    /// Menginstal cloudflared via Homebrew
    public func installCloudflared() {
        guard !isInstallingBinary else { return }
        self.isInstallingBinary = true
        self.installLogs = "Starting cloudflared installation via Homebrew...\n"

        BinaryDetector.shared.installViaBrew { [weak self] chunk in
            Task { @MainActor [weak self] in
                self?.installLogs.append(chunk)
            }
        } completion: { [weak self] success in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isInstallingBinary = false
                if success {
                    self.installLogs.append("\n✅ Installation successful!\n")
                    self.refreshBinaryStatus()
                    self.status = .stopped
                } else {
                    self.installLogs.append("\n❌ Installation failed. Try running 'brew install cloudflared' in Terminal.\n")
                }
            }
        }
    }

    /// Bersihkan log
    public func clearLogs() {
        self.logs.removeAll()
    }

    // MARK: - Internal Handlers

    private func handleProcessOutput(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        for line in lines where !line.isEmpty {
            self.appendLog(line)

            // Cek indikator sukses koneksi Cloudflare Tunnel
            let lower = line.lowercased()
            if lower.contains("registered tunnel connection") ||
               lower.contains("connection registered") ||
               lower.contains("connindex=") && lower.contains("registered") {
                if self.status != .running {
                    self.status = .running
                    self.appendLog("✅ Tunnel connected and active!")
                }
            } else if lower.contains("error") && (lower.contains("unauthorized") || lower.contains("invalid token") || lower.contains("failed to parse token")) {
                self.status = .error("Invalid Cloudflare token / authentication failed")
            }
        }
    }

    private func handleProcessTermination(exitCode: Int32) {
        self.outputPipe?.fileHandleForReading.readabilityHandler = nil

        if isUserInitiatedStop {
            self.status = .stopped
            self.appendLog("⏹️ Tunnel stopped.")
        } else {
            if exitCode == 0 {
                self.status = .stopped
                self.appendLog("⏹️ Tunnel process finished (exit 0).")
            } else {
                let errorMsg = "Tunnel stopped unexpectedly (exit code: \(exitCode))"
                self.status = .error(errorMsg)
                self.appendLog("⚠️ \(errorMsg)")
            }
        }
        cleanupProcessReferences()
    }

    private func cleanupProcessReferences() {
        self.process = nil
        self.outputPipe = nil
    }

    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")
        if logs.count > maxLogEntries {
            logs.removeFirst(logs.count - maxLogEntries)
        }
    }

    private func setupTerminationHook() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.forceKillSync()
            }
        }
    }

    /// Membunuh proses secara sinkron jika aplikasi di-quit
    public func forceKillSync() {
        if let proc = process, proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
    }
}
