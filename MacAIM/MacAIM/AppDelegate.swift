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
    private var config = Config.shared
    
    private var statusBarItem: NSStatusItem?
    private var window: NSWindow!
    private var initing: Bool = true
    
    func mainLoop() {
        while true {
            if config.action_showDashboard {
                DispatchQueue.main.async {
                    self.showWindow()
                    self.config.action_showDashboard = false
                }
            }
            if config.action_showStatusBarIcon{
                DispatchQueue.main.async {
                    self.createStatusBarItem()
                    self.config.action_showStatusBarIcon = false
                }
            }
            if config.action_hideStatusBarIcon {
                DispatchQueue.main.async {
                    self.removeStatusBarItem()
                    self.config.action_hideStatusBarIcon = false
                }
            }
            if config.action_updateMenuState {
                DispatchQueue.main.async {
                    self.updateMenuState()
                    self.config.action_updateMenuState = false
                }
            }
            // sleeps for 100 ms
            usleep(100000)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
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
        if config.silentStart {
            print("Starting silently")
            window.orderOut(nil)
        }

        // Set up the status bar
        if config.showStatusBarIcon {
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
    
    func registerStartAtLogin(_ startWithSystem: Bool) {
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
        config.debugMode = !config.debugMode
        
        // Update the menu item state
        if let item = self.statusBarItem?.menu?.item(withTitle: "Debug mode") {
            item.state = config.debugMode ? .on : .off
        }
    }
    
    @objc func toggleShowStatusBarIcon() {
        config.showStatusBarIcon = !config.showStatusBarIcon
        
        // Update the menu item state
        if let item = self.statusBarItem?.menu?.item(withTitle: "Status icon") {
            item.state = config.showStatusBarIcon ? .on : .off
            if config.showStatusBarIcon {
                config.action_showStatusBarIcon = true
            } else {
                config.action_hideStatusBarIcon = true
            }
        }
    }
    
    @objc func toggleStartAtLogin() {
        config.startAtLogin = !config.startAtLogin
        
        registerStartAtLogin(config.startAtLogin)
        
        // Update the menu item state
        if let item = self.statusBarItem?.menu?.item(withTitle: "Start at login") {
            item.state = config.startAtLogin ? .on : .off
        }
    }
    
    @objc func toggleSilentStart() {
        config.silentStart = !config.silentStart
        
        // Update the menu item state
        if let item = statusBarItem?.menu?.item(withTitle: "Silent start") {
            item.state = config.silentStart ? .on : .off
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
            registerStartAtLogin(config.startAtLogin)
            // Add "Start with System" checkbox to the menu
            let startWithSystemItem = NSMenuItem(title: "Start at login", action: #selector(toggleStartAtLogin), keyEquivalent: "a")
            startWithSystemItem.state = config.startAtLogin ? .on : .off
            menu.addItem(startWithSystemItem)
            
            // Add "Silent start" checkbox to the menu
            // silentStart have been set by previous code
            let silentStartItem = NSMenuItem(title: "Silent start", action: #selector(toggleSilentStart), keyEquivalent: "s")
            silentStartItem.state = config.silentStart ? .on : .off
            menu.addItem(silentStartItem)
            
            // Add "Status icon" checkbox to the menu
            let showStatusBarIconItem = NSMenuItem(title: "Status icon", action: #selector(toggleShowStatusBarIcon), keyEquivalent: "i")
            showStatusBarIconItem.state = config.showStatusBarIcon ? .on : .off
            menu.addItem(showStatusBarIconItem)
            
            // Add "Debug mode" checkbox to the menu
            let debugModeItem = NSMenuItem(title: "Debug mode", action: #selector(toggleDebugMode), keyEquivalent: "")
            debugModeItem.state = config.debugMode ? .on : .off
            menu.addItem(debugModeItem)
            
            menu.addItem(.separator())
            
            // Add "Quit" option to the menu
            let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            menu.addItem(quitItem)
            
            // Finally
            statusBarItem.menu = menu
        }
    }
    
    func updateMenuState() {
        // Status bar may be not created
        if config.showStatusBarIcon {
            config.action_showStatusBarIcon = true
        } else {
            config.action_hideStatusBarIcon = true
        }
        
        if let item = statusBarItem?.menu?.item(withTitle: "Debug mode") {
            item.state = config.debugMode ? .on : .off
        }
        if let item = statusBarItem?.menu?.item(withTitle: "Silent start") {
            item.state = config.silentStart ? .on : .off
        }
        if let item = statusBarItem?.menu?.item(withTitle: "Start at login") {
            item.state = config.startAtLogin ? .on : .off
        }
        if let item = statusBarItem?.menu?.item(withTitle: "Status icon") {
            item.state = config.showStatusBarIcon ? .on : .off
        }
    }
}
