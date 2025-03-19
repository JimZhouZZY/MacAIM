//
//  AppDelegate.swift
//  AutomaticInputSwitch
//
//  Created by Jim Zhou on 3/18/25.
//

import SwiftUI
import SwiftData
import AppKit
import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var window: NSWindow!

    let useDefaultKey = "useDefault"
    let startAtLoginKey = "startAtLogin"
    let silentStartKey = "silentStart"
    let debugModeKey = "debugMode"
    
    var debugMode: Bool = false
    var startWithSystem: Bool = false
    var silentStart: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Default settings
        if UserDefaults.standard.object(forKey: useDefaultKey) == nil {
            print("Using default settings")
            UserDefaults.standard.set(false, forKey: useDefaultKey)
            UserDefaults.standard.set(false, forKey: silentStartKey)
            UserDefaults.standard.set(false, forKey: startAtLoginKey)
            UserDefaults.standard.set(false, forKey: debugModeKey)
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
        window.title = "Automatic Input Switch"
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        // Hide window if silent start
        silentStart = UserDefaults.standard.bool(forKey: silentStartKey)
        if silentStart {
            print("Starting silently")
            window.orderOut(nil)
        }

        // Set up the status bar
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusBarItem = statusBarItem {
            statusBarItem.button?.title = "🖥"
            let menu = NSMenu()
            
            // Add "Dashboard" option to the menu
            let showWindowItem = NSMenuItem(title: "Dashboard", action: #selector(showWindow), keyEquivalent: "w")
            menu.addItem(showWindowItem)
            // Set action for the status bar button to show dashboard
            statusBarItem.button?.action = #selector(showWindow)
            
            // Check if the user wants the app to start with the system
            startWithSystem = UserDefaults.standard.bool(forKey: startAtLoginKey)
            registerStartAtLogin(startWithSystem: startWithSystem)
            // Add "Start with System" checkbox to the menu
            let startWithSystemItem = NSMenuItem(title: "Start at login", action: #selector(toggleStartWithSystem), keyEquivalent: "a")
            startWithSystemItem.state = startWithSystem ? .on : .off
            menu.addItem(startWithSystemItem)
            
            // Add "Silent start" checkbox to the menu
            // silentStart have been set by previous code
            let silentStartItem = NSMenuItem(title: "Silent start", action: #selector(toggleSilentStart), keyEquivalent: "s")
            silentStartItem.state = silentStart ? .on : .off
            menu.addItem(silentStartItem)
            
            // Add "Debug mode" checkbox to the menu
            debugMode = UserDefaults.standard.bool(forKey: debugModeKey)
            let debugModeItem = NSMenuItem(title: "Debug mode", action: #selector(toggleDebugMode), keyEquivalent: "d")
            debugModeItem.state = debugMode ? .on : .off
            menu.addItem(debugModeItem)
            
            // Add "Quit" option to the menu
            let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            menu.addItem(quitItem)
            
            // Finally
            statusBarItem.menu = menu
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
}
