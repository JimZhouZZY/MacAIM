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
            // These lines doesn't work, for now
            // If another instance is running, bring its window to the front
            UserDefaults.standard.set(true, forKey: "_showDashboard")
            
            // If there is already an instance running, exit the new one
            NSApplication.shared.terminate(nil)
        }
    }
    
    var body: some Scene {
        Settings {
        }
    }
}
