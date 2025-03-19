import SwiftUI
import SwiftData
import AppKit

@main
struct AutomaticInputSwitchApp: App {

    init() {
        // Prevent multiple instances
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
        if runningApps.count > 1 {
            // If there is already an instance running, exit the new one
            NSApplication.shared.terminate(nil)
        }
    }
    
    var body: some Scene {
        Window("Automatic Input Switch", id: "MainWindow") {
            ContentView()
        }
        .defaultSize(width: 600, height: 600)
    }
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
}
