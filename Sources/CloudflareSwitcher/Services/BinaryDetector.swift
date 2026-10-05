import Foundation

/// Layanan untuk mendeteksi binary cloudflared dan menginisiasi instalasi jika belum ada
public final class BinaryDetector: Sendable {
    public static let shared = BinaryDetector()

    private init() {}

    /// Lokasi umum binary cloudflared di macOS
    private let commonCloudflaredPaths = [
        "/opt/homebrew/bin/cloudflared",
        "/usr/local/bin/cloudflared",
        "/usr/bin/cloudflared"
    ]

    /// Lokasi umum Homebrew di macOS
    private let commonBrewPaths = [
        "/opt/homebrew/bin/brew",
        "/usr/local/bin/brew"
    ]

    /// Menemukan path binary cloudflared yang valid
    public func findCloudflaredPath() -> String? {
        let fileManager = FileManager.default

        // 1. Cek direktori standar
        for path in commonCloudflaredPaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        // 2. Coba cari via 'which cloudflared'
        if let whichPath = runCommandSync(launchPath: "/usr/bin/which", arguments: ["cloudflared"]),
           fileManager.isExecutableFile(atPath: whichPath) {
            return whichPath
        }

        return nil
    }

    /// Menemukan path binary brew
    public func findBrewPath() -> String? {
        let fileManager = FileManager.default
        for path in commonBrewPaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }
        if let whichPath = runCommandSync(launchPath: "/usr/bin/which", arguments: ["brew"]),
           fileManager.isExecutableFile(atPath: whichPath) {
            return whichPath
        }
        return nil
    }

    /// Apakah cloudflared sudah terinstall
    public var isCloudflaredInstalled: Bool {
        return findCloudflaredPath() != nil
    }

    /// Apakah Homebrew terinstall
    public var isBrewInstalled: Bool {
        return findBrewPath() != nil
    }

    /// Menjalankan perintah sinkron sederhana untuk cek path
    private func runCommandSync(launchPath: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                return output
            }
        } catch {
            return nil
        }
        return nil
    }

    /// Menjalankan instalasi cloudflared via Homebrew secara asynchronous
    public func installViaBrew(
        onOutput: @escaping @Sendable (String) -> Void,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        guard let brewPath = findBrewPath() else {
            onOutput("Error: Homebrew (brew) is not found on this system.\nPlease install Homebrew from https://brew.sh")
            completion(false)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "cloudflared"]

            // Environment PATH agar brew dapat berjalan dengan benar
            var env = ProcessInfo.processInfo.environment
            let currentPath = env["PATH"] ?? ""
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + currentPath
            env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
            process.environment = env

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let outHandle = pipe.fileHandleForReading
            outHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                    DispatchQueue.main.async {
                        onOutput(str)
                    }
                }
            }

            do {
                try process.run()
                process.waitUntilExit()

                outHandle.readabilityHandler = nil
                let success = (process.terminationStatus == 0) && (self.findCloudflaredPath() != nil)
                DispatchQueue.main.async {
                    completion(success)
                }
            } catch {
                outHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    onOutput("Gagal menjalankan installer: \(error.localizedDescription)\n")
                    completion(false)
                }
            }
        }
    }
}
