import SwiftUI
import SwiftData
import AppKit

@main
struct AutomaticInputSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Prevent multiple instances
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
        if runningApps.count > 1 {
            // If there is already an instance running, exit the new one
            NSApplication.shared.terminate(nil)
        }
    }
    
    var body: some Scene {
        Settings {
        }
        .defaultSize(width: 600, height: 600)
    }
}
