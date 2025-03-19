import SwiftUI
import SwiftData
import Foundation
import Carbon
import AppKit
import Cocoa

struct ContentView: View {
    @ObservedObject var appNameToInputSourceModel: AppNameToInputSourceModel
    
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @State private var apps: [String] = []
    @State private var currentAppName: String? = nil
    @State private var selectedApp: String?  // Store the selected app
    @State private var searchText: String = ""  // Search text for filtering
    @State private var appNameToInputSource: [String: TISInputSource?] = [:]
    @State private var sortOption: SortOption = .name
    @State private var appAddedDates: [String: Date] = [:]
    @State private var isReversed: Bool = false // Added state variable for reverse sorting
    @State private var inputSources = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    @State private var recognizedInputSources = TISCreateInputSourceList(nil, false)
                                                    .takeRetainedValue() as! [TISInputSource]

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case dateAdded = "Date Added"
        case inputMethod = "Input Method"
    }

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
        let sortedApps: [String]
        
        switch sortOption {
        case .name:
            sortedApps = apps.sorted()
        case .dateAdded:
            sortedApps = apps.sorted { (app1, app2) in
                let date1 = appAddedDates[app1] ?? Date.distantPast
                let date2 = appAddedDates[app2] ?? Date.distantPast
                return date1 > date2
            }
        case .inputMethod:
            sortedApps = apps.sorted { (app1, app2) in
                let input1 = appNameToInputSource[app1].flatMap { inputMethodNames[getInputMethodName($0!)] } ?? ""
                let input2 = appNameToInputSource[app2].flatMap { inputMethodNames[getInputMethodName($0!)]  } ?? ""
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
                        .foregroundColor(.gray)
                        .padding(.leading, 8)

                    TextField("Search for an app", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                }
            }
            .frame(height: 36)
            .padding(.horizontal)

            HStack {
                Picker("Sort by: ", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .animation(.easeInOut(duration: 0.3), value: sortOption)

                Toggle("Reversed", isOn: $isReversed)
                    .transition(.opacity.combined(with: .move(edge: .trailing))) // 平滑切换
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)

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
                        if !debugMode {
                            // TODO: sort it
                            ForEach(recognizedInputSources, id: \.self) { inputSource in
                                Text(inputMethodNames[getInputMethodName(inputSource)] ??
                                     ("Unrecognized: " + getInputMethodName(inputSource)))
                                .tag(inputSource)
                            }
                        } else {
                            ForEach(inputSources, id: \.self) { inputSource in
                                Text(inputMethodNames[getInputMethodName(inputSource)] ??
                                     ("Unrecognized: " + getInputMethodName(inputSource)))
                                .tag(inputSource)
                            }
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
                loadApplications()
                loadInputMethods()
                getRecognizedInputSources()
            }
        }
        .padding()
    }
    
    func getRecognizedInputSources() {
        recognizedInputSources.removeAll() // Avoid repeatedly adding
        for inputSource in inputSources {
            if inputMethodNames[getInputMethodName(inputSource)] != nil {
                recognizedInputSources.append(inputSource)
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
            for appURL in appURLs {
                let attributes = try? fileManager.attributesOfItem(atPath: appURL.path)
                if let creationDate = attributes?[.creationDate] as? Date {
                    appAddedDates[appURL.lastPathComponent] = creationDate
                }
            }
            apps = appURLs
                .filter { $0.pathExtension == "app" }
                .compactMap { url -> String? in
                    let values = try? url.resourceValues(forKeys: [.localizedNameKey])
                    return values?.localizedName
                }
            
            for appName in apps {
                if appNameToInputSource[appName] == nil {
                    appNameToInputSource[appName] = inputSources.first
                }
            }
        } catch {
            print("Error loading applications: \(error)")
        }
    }
}
