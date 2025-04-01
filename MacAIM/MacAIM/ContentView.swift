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
import Foundation
import Carbon
import AppKit
import Cocoa

struct ContentView: View {
    var settingsWindowController: NSWindowController?
    
    @State private var config = Config.shared
    @State private var selectedApp: String?
    @State private var searchText: String = ""  // Search text for filtering
    @State private var sortOption: SortOption = .name
    @State private var appAddedDates: [String: Date] = [:]
    @State private var isReversed: Bool = false // Is sorting result reverted
    @State private var settingsWindow: NSWindow?

    enum SortOption: String, CaseIterable {
        case name = "sort::Name"
        case dateAdded = "sort::DateAdded"
        case inputMethod = "sort::InputMethod"
        
        var localized: String {
            return NSLocalizedString(self.rawValue, comment: "")
        }
    }
    
    // Filter the apps based on the search text
    var filteredApps: [String] {
        let sortedApps: [String]
        
        switch sortOption {
        case .name:
            sortedApps = inputSourceManager.apps.sorted()
        case .dateAdded:
            sortedApps = inputSourceManager.apps.sorted { (app1, app2) in
                let date1 = appAddedDates[app1] ?? Date.distantPast
                let date2 = appAddedDates[app2] ?? Date.distantPast
                return date1 > date2
            }
        case .inputMethod:
            sortedApps = inputSourceManager.apps.sorted { (app1, app2) in
                let input1 = inputSourceManager.getInputSourceForAppName(app1).flatMap { inputSourceManager.getInputSourceNameFromInputSource($0) } ?? ""
                let input2 = inputSourceManager.getInputSourceForAppName(app2).flatMap { inputSourceManager.getInputSourceNameFromInputSource($0)  } ?? ""
                return input1 > input2
            }
        }
        let finalSortedApps = isReversed ? sortedApps.reversed() : sortedApps

        if searchText.isEmpty {
            return Array(finalSortedApps)
        } else {
            return Array(finalSortedApps.filter { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        VStack {
            // Search Bar
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(radius: searchText.isEmpty ? 3 : 6) // 增强输入时的阴影效果
                    .animation(.easeInOut(duration: 0.3), value: searchText) // 添加动画

                HStack {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)

                    TextField("Search for an app", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                    
                    Button(action: {
                        openSettingsWindow()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 36)
            .padding(.horizontal)

            HStack {
                Picker("Sort by: ", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.localized).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .animation(.easeInOut(duration: 0.3), value: sortOption)

                Toggle("Reversed", isOn: $isReversed)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)

            // List of apps with keyboard navigation
            List(filteredApps, id: \.self, selection: $selectedApp) { appName in
                HStack {
                    if let appIcon = getAppIconFromAppName(for: appName) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 48, height: 48) // Adjust icon size
                            .clipShape(RoundedRectangle(cornerRadius: 6)) // Optional: Rounded corners
                    }
                    
                    VStack(alignment: .leading) {
                        Text(appName)

                        // Show the "Date Added" when sorted by date
                        if sortOption == .dateAdded, let dateAdded = appAddedDates[appName] {
                            Text("Added on: \(formattedDate(dateAdded))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if config.debugMode, let bundleIdentifier = inputSourceManager.appNameToBundleIdentifier[appName] {
                            Text(bundleIdentifier)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                    Picker("Input: ", selection: Binding(
                        get: {
                            if let inputSource = inputSourceManager.appNameToInputSource[appName]{
                                if let inputMethodName = inputSourceManager.getInputSourceNameFromInputSource(inputSource!) {
                                    return inputMethodName
                                }
                                else if config.debugMode {
                                    let inputMethod = inputSourceManager.getInputSourceNameFromInputSource(inputSource!)!
                                    return inputMethod
                                }
                            }
                            return "Default"  // Return a default value when no input method is available
                        },
                        set: { (newValue: String) in
                            if !config.debugMode {
                                if let inputSource = inputSourceManager.inputSources.first(where: { inputSourceManager.getInputSourceNameFromInputSource($0) == newValue }) {
                                    inputSourceManager.appNameToInputSource[appName] = inputSource
                                } else {
                                    // Handle case where inputSource is not found
                                    inputSourceManager.appNameToInputSource[appName] = nil
                                }
                                inputSourceManager.saveInputMethods()
                            } else {
                                if let inputSource = inputSourceManager.inputSources.first(where: { inputSourceManager.getInputSourceNameFromInputSource($0)  == newValue }) {
                                    inputSourceManager.appNameToInputSource[appName] = inputSource
                                } else if let inputSource = inputSourceManager.inputSources.first(where: { inputSourceManager.getInputSourceNameFromInputSource($0)  == newValue }) {
                                    inputSourceManager.appNameToInputSource[appName] = inputSource
                                } else {
                                    // Handle case where inputSource is not found
                                    inputSourceManager.appNameToInputSource[appName] = nil
                                }
                                inputSourceManager.saveInputMethods()
                            }
                        }
                    )) {
                        if !config.debugMode {
                            // TODO: sort it
                            ForEach(inputSourceManager.recognizedInputSources, id: \.self) { inputSource in
                                let name = inputSourceManager.getInputSourceNameFromInputSource(inputSource) ?? ("Unrecognized: " + inputSourceManager.getInputSourceBundleNameFromInputSource(inputSource))
                                Text(name)
                                    .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                            }
                            Text(String(format: NSLocalizedString("Default: %@", comment: ""), String(format: NSLocalizedString(config.defaultInputSourceName, comment: ""))))
                                .tag("Default")
                        } else {
                            ForEach(inputSourceManager.inputSources, id: \.self) { inputSource in
                                let name = inputSourceManager.getInputSourceNameFromInputSource(inputSource) ?? ("Unrecognized: " + inputSourceManager.getInputSourceBundleNameFromInputSource(inputSource))
                                Text(name)
                                    .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                            }
                            Text("Default: " + config.defaultInputSourceName)
                                .tag("Default")
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown menu
                    .frame(width: 200)
                }
                .listRowBackground(
                    LinearGradient(
                        gradient: Gradient(colors: selectedApp == appName ? [Color.blue.opacity(0.3), Color.blue.opacity(0.1)] : [Color.clear, Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: filteredApps)
                .padding(.vertical, 8)
            }
            .onAppear {
            }
        }
        .padding()
    }
    
    func toggleStatusBarIcon() {
        let show = UserDefaults.standard.object(forKey: "showStatusBarIcon") as! Bool
        UserDefaults.standard.set(!show, forKey: "showStatusBarIcon")
        if show {
            UserDefaults.standard.set(true, forKey: "_hideStatusBarIcon")
        } else {
            UserDefaults.standard.set(true, forKey: "_showStatusBarIcon")
        }
    }
    
    func getAppIconFromAppName(for appName: String) -> NSImage? {
        let appPath = "/Applications/\(appName).app"
        return NSWorkspace.shared.icon(forFile: appPath)
    }
    
    func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView()

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 250),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.center()
        newWindow.title = "Settings"
        newWindow.contentView = NSHostingView(rootView: settingsView)
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        settingsWindow = newWindow

        // Handle window closing
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: newWindow, queue: nil) { _ in
            self.settingsWindow = nil
            UserDefaults.standard.set(true, forKey: "_updateMenuState")
        }
    }
}

func time() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let currentDate = Date()
    return formatter.string(from: currentDate)
}

func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}
