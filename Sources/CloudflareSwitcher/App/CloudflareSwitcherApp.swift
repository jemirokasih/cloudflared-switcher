import SwiftUI
import AppKit

@main
struct CloudflareSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tunnelManager = TunnelManager.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: tunnelManager.status.iconName)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Mode accessory: sembunyikan dari Dock, hanya aktif di menu bar
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        TunnelManager.shared.forceKillSync()
    }
}
