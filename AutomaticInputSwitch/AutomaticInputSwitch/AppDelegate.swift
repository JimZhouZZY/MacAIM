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
    var winclosed = false
    let startupKey = "startAtLogin"
    let silentStartKey = "silentStart"
    var silentStart = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Set up the status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusBarItem = statusBarItem {
            statusBarItem.button?.title = "🖥"
            let menu = NSMenu()
            
            // Add "Quit" option to the menu
            let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            menu.addItem(quitItem)
            
            // Add "Show Window" option to the menu
            let showWindowItem = NSMenuItem(title: "Dashboard", action: #selector(showWindow), keyEquivalent: "w")
            menu.addItem(showWindowItem)
            
            // Check if the user wants the app to start with the system
            let startWithSystem = UserDefaults.standard.bool(forKey: startupKey)
            if startWithSystem {
                // Register the app to start at login
                do {
                    try SMAppService.mainApp.register()
                } catch {
                    print("An Error occurred: \(error)")
                }
            }
            
            // Add "Start with System" checkbox to the menu
            let startWithSystemItem = NSMenuItem(title: "Start at login", action: #selector(toggleStartWithSystem), keyEquivalent: "")
            startWithSystemItem.state = startWithSystem ? .on : .off
            menu.addItem(startWithSystemItem)
            
            // Add "Silent start" checkbox to the menu
            silentStart = UserDefaults.standard.bool(forKey: silentStartKey)
            let silentStartItem = NSMenuItem(title: "Silent start", action: #selector(toggleSilentStart), keyEquivalent: "")
            silentStartItem.state = silentStart ? .on : .off
            menu.addItem(silentStartItem)
            
            statusBarItem.menu = menu
            
            // Set action for the status bar button to show window
            statusBarItem.button?.action = #selector(showWindow)
        }
        
        // Initialize the window
        let contentView = ContentView()
        //window = NSWindow(
        //    contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
        //    styleMask: [.titled, .closable, .miniaturizable, .resizable],
        //    backing: .buffered,
        //    defer: false
        //)
        window = NSApp.windows[0]
        if String(describing: type(of: window)) != "SwiftUI.AppKitWindow" {
            NSApp.windows[1]
        }
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        // Why dont this title work?
        window.title = "Automatic Input Switch"
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false // Keep the window in memory

        if silentStart {
            if window != nil {
                print("Starting silently")
                window.orderOut(nil)
                var elapsed = 0.0
                let interval = 0.1 // 100ms
                let duration = 1.0 // 5 seconds

                Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                    elapsed += interval
                    print(NSApplication.shared.windows.first)
                    NSApplication.shared.windows.first?.performClose(nil)
                    print(self.winclosed)
                    if elapsed >= duration {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide the window instead of quitting the app
        sender.orderOut(nil)
        winclosed = true
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func showWindow() {
        if let window = window {
            if true { //winclosed
                //print(NSApp.windows)
                window.makeKeyAndOrderFront(nil)
                //window.orderOut(nil)
            }
        }
    }
    
    @objc func toggleStartWithSystem() {
        let startWithSystem = !UserDefaults.standard.bool(forKey: startupKey)
        UserDefaults.standard.set(startWithSystem, forKey: startupKey)
        
        
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
        
        // Update the menu item state
        if let item = statusBarItem?.menu?.item(withTitle: "Start with System") {
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
