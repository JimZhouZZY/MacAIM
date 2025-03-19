import SwiftUI
import SwiftData
import Foundation
import Carbon
import AppKit
import Cocoa

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var inputSources = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    @State private var appNameToInputSource: [String: TISInputSource?] = [:]
    @State private var currentAppName: String? = nil
    @State private var apps: [String] = []
    @State private var searchText: String = ""  // Search text for filtering
    @State private var selectedApp: String?  // Store the selected app
    
    // Define a dictionary to map system input source IDs to user-friendly names
    let inputMethodNames: [String: String] = [
        "com.apple.keylayout.ABC": "English",
        "com.apple.inputmethod.SCIM.ITABC": "Pinyin - Simplified",
        "com.apple.keylayout.US": "US Keyboard",
        "com.apple.inputmethod.Kotoeri": "Japanese - Kotoeri",
        "com.apple.inputmethod.SimplifiedChinese": "Simplified Chinese",
        "com.apple.inputmethod.TCIM.Pinyin": "Pinyin - Traditional",
        // TODO: more mappings
    ]
    
    // Filter the apps based on the search text
    var filteredApps: [String] {
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack {
            // Search Bar
            TextField("Search for an app", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // List of apps with keyboard navigation
            List(filteredApps, id: \.self, selection: $selectedApp) { appName in
                HStack {
                    if let appIcon = getAppIcon(for: appName) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 48, height: 48) // Adjust icon size
                            .clipShape(RoundedRectangle(cornerRadius: 6)) // Optional: Rounded corners
                    }
                    Text(appName)
                    Spacer()
                    Picker("Input Method", selection: Binding(
                        get: {
                            return appNameToInputSource[appName] ?? inputSources.first!
                        },
                        set: { newValue in
                            appNameToInputSource[appName] = newValue
                            saveInputMethods()
                        }
                    )) {
                        // TODO: sort it
                        ForEach(inputSources, id: \.self) { inputSource in
                            Text(inputMethodNames[getInputMethodName(inputSource)] ??
                                 ("Unrecognized: " + getInputMethodName(inputSource)))
                            .tag(inputSource)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown menu
                    .frame(width: 200)
                }
                .padding()
            }
            .onAppear {
                loadApplications()
                loadInputMethods()
                mainLoop()
            }
        }
        .padding()
    }
    
    func mainLoop() {
        // Run the loop in a background thread
        DispatchQueue.global(qos: .background).async {
            while true {
                let retval: (String?, String?) = getCurrentAppName()
                let appName = retval.0 ?? ""
                if appName != "" {
                    let lastAppName = retval.1 ?? ""
                    // Only trigger when the app name changes
                    if !(appName == lastAppName) {
                        print("User is now using: \(appName)")
                        if let inputSource = appNameToInputSource[appName] ?? inputSources.first {
                            // Ensure switchInputMethod is called on the main thread
                            DispatchQueue.main.async {
                                switchInputSource(to: inputSource)
                            }
                        } else {
                            print("No input method found for \(appName)")
                        }
                    }
                } else {
                    print("Unable to get the current app name")
                }
                // sleeps for 10 ms
                usleep(10000)
            }
        }
    }
    
    func getAppIcon(for appName: String) -> NSImage? {
        let appPath = "/Applications/\(appName).app"
        return NSWorkspace.shared.icon(forFile: appPath)
    }
    
    func getInputMethodName(_ inputSource: TISInputSource) -> String {
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let inputSourceIDString = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return inputSourceIDString
        }
        return "Unknown"
    }
    
    func saveInputMethods() {
        do {
            var saveDict: [String: String] = [:]
            for (appName, inputSource) in appNameToInputSource {
                if let inputSource = inputSource {
                    let inputSourceID = getInputMethodName(inputSource)
                    saveDict[appName] = inputSourceID
                }
            }
            let encoder = JSONEncoder()
            let data = try encoder.encode(saveDict)
            UserDefaults.standard.set(data, forKey: "inputMethodToInputSource")
        } catch {
            print("Failed to save input methods: \(error)")
        }
    }
    
    func loadInputMethods() {
        if let savedData = UserDefaults.standard.data(forKey: "inputMethodToInputSource") {
            do {
                let decoder = JSONDecoder()
                let decodedDict = try decoder.decode([String: String].self, from: savedData)
                var restoredDict: [String: TISInputSource?] = [:]
                for (appName, inputSourceID) in decodedDict {
                    if let inputSource = inputSources.first(where: { getInputMethodName($0) == inputSourceID }) {
                        restoredDict[appName] = inputSource
                    }
                }
                appNameToInputSource = restoredDict
            } catch {
                print("Failed to load input methods: \(error)")
            }
        }
    }
    
    func loadApplications() {
        let fileManager = FileManager.default
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        
        do {
            let appURLs = try fileManager.contentsOfDirectory(at: applicationsURL, includingPropertiesForKeys: nil)
            apps = appURLs
                .filter { $0.pathExtension == "app" }
                .map { $0.deletingPathExtension().lastPathComponent }
            
            for appName in apps {
                if appNameToInputSource[appName] == nil {
                    appNameToInputSource[appName] = inputSources.first
                }
            }
        } catch {
            print("Error loading applications: \(error)")
        }
    }
    
    func switchInputSource(to inputSource: TISInputSource) {
        TISSelectInputSource(inputSource)
        return
    }
}

var lastAppName = ""
func getCurrentAppName() -> (String, String) {
    let lastlastAppName = lastAppName
    if let frontApp = NSWorkspace.shared.frontmostApplication {
        lastAppName = frontApp.localizedName ?? ""
        return (lastAppName, lastlastAppName)
    }
    return ("", lastlastAppName)
}
