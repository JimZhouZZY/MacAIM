/*
    MacAIM
    Copyright (C) 2025 Jim Zhou

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.
*/

import SwiftUI
import SwiftData
import AppKit
import Cocoa
import ServiceManagement
import Foundation
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var window: NSWindow!
    
    let useDefaultKey = "useDefault"
    let startAtLoginKey = "startAtLogin"
    let silentStartKey = "silentStart"
    let debugModeKey = "debugMode"
    let showStatusBarIconKey = "showStatusBarIcon"
    
    private var startAtLogin = false
    private var silentStart = false
    private var debugMode = false
    private var showStatusBarIcon = true
    
    @AppStorage("_clean") private var _clean = false
    
    var initing: Bool = true
    
    func mainLoop() {
        while true {
            if let _showDashboard = UserDefaults.standard.object(forKey: "_showDashboard") {
                if _showDashboard as! Bool {
                    print("_showDashboard")
                    DispatchQueue.main.async {
                        self.showWindow()
                        UserDefaults.standard.set(false, forKey: "_showDashboard")
                    }
                }
            }
            if let _showStatusBarIcon = UserDefaults.standard.object(forKey: "_showStatusBarIcon") {
                if _showStatusBarIcon as! Bool {
                    print("_showStatusBarIcon")
                    DispatchQueue.main.async {
                        self.createStatusBarItem()
                        UserDefaults.standard.set(false, forKey: "_showStatusBarIcon")
                    }
                }
            }
            if let _hideStatusBarIcon = UserDefaults.standard.object(forKey: "_hideStatusBarIcon") {
                if _hideStatusBarIcon as! Bool {
                    print("_hideStatusBarIcon")
                    DispatchQueue.main.async {
                        self.removeStatusBarItem()
                        UserDefaults.standard.set(false, forKey: "_hideStatusBarIcon")
                    }
                }
            }
            if let _updateMenuState = UserDefaults.standard.object(forKey: "_updateMenuState") {
                if _updateMenuState as! Bool {
                    print("_updateMenuState")
                    DispatchQueue.main.async {
                        self.loadConfig()
                        self.updateMenuState()
                        UserDefaults.standard.set(false, forKey: "_updateMenuState")
                    }
                }
            }
            // sleeps for 100 ms
            usleep(100000)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Default settings
        // This line prevents debug mode to be set
        // Debug mode should always be set manually
        // This line is still under consideration UserDefaults.standard.set(false, forKey: debugModeKey)
        // **DO THESE CHECKS** or there might be unexpected crash
        if (UserDefaults.standard.object(forKey: useDefaultKey) == nil ||
            UserDefaults.standard.object(forKey: silentStartKey) == nil ||
            UserDefaults.standard.object(forKey: startAtLoginKey) == nil ||
            UserDefaults.standard.object(forKey: debugModeKey) == nil ||
            UserDefaults.standard.object(forKey: showStatusBarIconKey) == nil ||
            UserDefaults.standard.object(forKey: "defaultInputSourceName") == nil ||
            UserDefaults.standard.object(forKey: "_showDashboard") == nil ||
            UserDefaults.standard.object(forKey: "_showStatusBarIcon") == nil ||
            UserDefaults.standard.object(forKey: "_hideStatusBarIcon") == nil ||
            UserDefaults.standard.object(forKey: "_updateMenuState") == nil) ||
            UserDefaults.standard.object(forKey: "_clean") == nil ||
            UserDefaults.standard.object(forKey: "appNameToInputSource") == nil ||
            _clean == true
        {
            do {
                print("Using default settings")
                UserDefaults.standard.set(false, forKey: useDefaultKey)
                UserDefaults.standard.set(false, forKey: silentStartKey)
                UserDefaults.standard.set(false, forKey: startAtLoginKey)
                UserDefaults.standard.set(false, forKey: debugModeKey)
                UserDefaults.standard.set(true, forKey: showStatusBarIconKey)
                UserDefaults.standard.set("None", forKey: "defaultInputSourceName")
                UserDefaults.standard.set(false, forKey: "_showDashboard")
                UserDefaults.standard.set(false, forKey: "_showStatusBarIcon")
                UserDefaults.standard.set(false, forKey: "_hideStatusBarIcon")
                UserDefaults.standard.set(false, forKey: "_updateMenuState")
                UserDefaults.standard.set(false, forKey: "_clean")
                var saveDict: [String: String] = [:]
                var apps: [String] = []
                let fileManager = FileManager.default
                let applicationsURL = URL(fileURLWithPath: "/Applications")
                do {
                    let appURLs = try fileManager.contentsOfDirectory(at: applicationsURL, includingPropertiesForKeys: nil)
                    apps = appURLs
                        .filter { $0.pathExtension == "app" }
                        .map { $0.deletingPathExtension().lastPathComponent }
                } catch {
                    print("Error loading applications: \(error)")
                }
                for appName in apps {
                    saveDict[appName] = "Default"
                }
                let encoder = JSONEncoder()
                let data = try encoder.encode(saveDict)
                UserDefaults.standard.set(data, forKey: "appNameToInputSource")
            } catch {
                print("Failed to init default settings: \(error)")
            }
        }
        
        // Initialize the window
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        // Why dont this title work?
        window.title = "MacAIM - " + String(localized: "Automatic Input Switch")
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        // Hide window if silent start
        silentStart = UserDefaults.standard.bool(forKey: silentStartKey)
        if silentStart {
            print("Starting silently")
            window.orderOut(nil)
        }

        // Set up the status bar
        showStatusBarIcon = UserDefaults.standard.bool(forKey: showStatusBarIconKey)
        if showStatusBarIcon {
            createStatusBarItem()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.initing = false
        }
        
        DispatchQueue.global(qos: .background).async {
            self.mainLoop()
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide the window instead of quitting the app
        sender.orderOut(nil)
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func registerStartAtLogin(startWithSystem: Bool) {
        // Use SMAppService instead of SMLoginItemSetEnabled
        if startWithSystem {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("An Error occurred: \(error)")
            }
        } else {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                print("An Error occurred: \(error)")
            }
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            
            // Ensure the app remains in accessory mode
            // This is neccessary
            NSApp.setActivationPolicy(.accessory)
            
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func toggleDebugMode() {
        let debugMode = !UserDefaults.standard.bool(forKey: debugModeKey)
        UserDefaults.standard.set(debugMode, forKey: debugModeKey)
        
        // Update the menu item state
        if let item = self.statusBarItem?.menu?.item(withTitle: "Debug mode") {
            item.state = debugMode ? .on : .off
        }
    }
    
    @objc func toggleShowStatusBarIcon() {
        let showStatusBarIcon = !UserDefaults.standard.bool(forKey: showStatusBarIconKey)
        UserDefaults.standard.set(showStatusBarIcon, forKey: showStatusBarIconKey)
        
        // Update the menu item state
        if let item = self.statusBarItem?.menu?.item(withTitle: "Status icon") {
            item.state = showStatusBarIcon ? .on : .off
            if showStatusBarIcon {
                UserDefaults.standard.set(true, forKey: "_showStatusBarIcon")
            } else {
                UserDefaults.standard.set(true, forKey: "_hideStatusBarIcon")
            }
        }
    }
    
    @objc func toggleStartWithSystem() {
        let startWithSystem = !UserDefaults.standard.bool(forKey: startAtLoginKey)
        UserDefaults.standard.set(startWithSystem, forKey: startAtLoginKey)
        
        registerStartAtLogin(startWithSystem: startWithSystem)
        
        // Update the menu item state
        if let item = self.statusBarItem?.menu?.item(withTitle: "Start at login") {
            item.state = startWithSystem ? .on : .off
        }
    }
    
    @objc func toggleSilentStart() {
        let silentStart = !UserDefaults.standard.bool(forKey: silentStartKey)
        UserDefaults.standard.set(silentStart, forKey: silentStartKey)
        
        // Update the menu item state
        if let item = statusBarItem?.menu?.item(withTitle: "Silent start") {
            item.state = silentStart ? .on : .off
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if !initing {
            print("App gained focus")
            showWindow()
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        print("App lost focus")
    }
    
    func removeStatusBarItem() {
        if let item = statusBarItem {
            NSStatusBar.system.removeStatusItem(item)
            statusBarItem = nil
        }
    }
    
    func createStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusBarItem = statusBarItem {
            if let button = statusBarItem.button {
                let title = NSMutableAttributedString(string: "iM", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
                    .strokeWidth: -2.0
                ])
                button.attributedTitle = title
            }

            let menu = NSMenu()
            
            // Add "Dashboard" option to the menu
            let showWindowItem = NSMenuItem(title: "Dashboard", action: #selector(showWindow), keyEquivalent: "d")
            menu.addItem(showWindowItem)
            // Set action for the status bar button to show dashboard
            statusBarItem.button?.action = #selector(showWindow)
            
            menu.addItem(.separator())
            
            // Check if the user wants the app to start with the system
            startAtLogin = UserDefaults.standard.bool(forKey: startAtLoginKey)
            registerStartAtLogin(startWithSystem: startAtLogin)
            // Add "Start with System" checkbox to the menu
            let startWithSystemItem = NSMenuItem(title: "Start at login", action: #selector(toggleStartWithSystem), keyEquivalent: "a")
            startWithSystemItem.state = startAtLogin ? .on : .off
            menu.addItem(startWithSystemItem)
            
            // Add "Silent start" checkbox to the menu
            // silentStart have been set by previous code
            let silentStartItem = NSMenuItem(title: "Silent start", action: #selector(toggleSilentStart), keyEquivalent: "s")
            silentStartItem.state = silentStart ? .on : .off
            menu.addItem(silentStartItem)
            
            // Add "Status icon" checkbox to the menu
            showStatusBarIcon = UserDefaults.standard.bool(forKey: showStatusBarIconKey)
            let showStatusBarIconItem = NSMenuItem(title: "Status icon", action: #selector(toggleShowStatusBarIcon), keyEquivalent: "i")
            showStatusBarIconItem.state = showStatusBarIcon ? .on : .off
            menu.addItem(showStatusBarIconItem)
            
            // Add "Debug mode" checkbox to the menu
            debugMode = UserDefaults.standard.bool(forKey: debugModeKey)
            let debugModeItem = NSMenuItem(title: "Debug mode", action: #selector(toggleDebugMode), keyEquivalent: "")
            debugModeItem.state = debugMode ? .on : .off
            menu.addItem(debugModeItem)
            
            menu.addItem(.separator())
            
            // Add "Quit" option to the menu
            let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            menu.addItem(quitItem)
            
            // Finally
            statusBarItem.menu = menu
        }
    }
    
    func loadConfig() {
        silentStart = UserDefaults.standard.bool(forKey: silentStartKey)
        startAtLogin = UserDefaults.standard.bool(forKey: startAtLoginKey)
        showStatusBarIcon = UserDefaults.standard.bool(forKey: showStatusBarIconKey)
        debugMode = UserDefaults.standard.bool(forKey: debugModeKey)
    }
    
    func updateMenuState() {
        // Status bar may be not created
        if showStatusBarIcon {
            UserDefaults.standard.set(true, forKey: "_showStatusBarIcon")
        } else {
            UserDefaults.standard.set(true, forKey: "_hideStatusBarIcon")
        }
        
        if let item = statusBarItem?.menu?.item(withTitle: "Debug mode") {
            print(item,debugMode)
            item.state = debugMode ? .on : .off
        }
        if let item = statusBarItem?.menu?.item(withTitle: "Silent start") {
            item.state = silentStart ? .on : .off
        }
        if let item = statusBarItem?.menu?.item(withTitle: "Start at login") {
            item.state = startAtLogin ? .on : .off
        }
        if let item = statusBarItem?.menu?.item(withTitle: "Status icon") {
            item.state = showStatusBarIcon ? .on : .off
        }
    }
}
