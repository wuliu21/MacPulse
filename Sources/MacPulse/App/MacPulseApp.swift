import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: HUDSettings!
    private var coordinator: TelemetryCoordinator!
    private var panel: FloatingHUDPanel!
    private var statusBarController: StatusBarController!

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide Dock icon and Cmd+Tab entry; live purely as a Desktop HUD + Menu Bar utility
        NSApp.setActivationPolicy(.accessory)

        let hudSettings = HUDSettings()
        let telemetry = TelemetryCoordinator(settings: hudSettings)
        let hudPanel = FloatingHUDPanel(coordinator: telemetry, settings: hudSettings)
        let statusBar = StatusBarController(coordinator: telemetry, settings: hudSettings, panel: hudPanel)

        self.settings = hudSettings
        self.coordinator = telemetry
        self.panel = hudPanel
        self.statusBarController = statusBar

        hudPanel.orderFrontRegardless()
    }
}

@main
public struct MacPulseMain {
    public static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
