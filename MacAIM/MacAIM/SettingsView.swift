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
import AppKit
import Foundation
import Carbon
import AppKit
import Cocoa
import SwiftData

struct SettingsView: View {
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("silentStart") private var silentStart = false
    @AppStorage("debugMode") private var debugMode = false
    @AppStorage("showStatusBarIcon") private var showStatusBarIcon = true
    @AppStorage("defaultInputSourceName") private var defaultInputSourceName = "None"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    @State private var inputSources = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    @State private var recognizedInputSources = TISCreateInputSourceList(nil, false)
                                                    .takeRetainedValue() as! [TISInputSource]
    @State private var showAlert = false
    @State private var showLanguageAlert = false
    @State private var resetConfirmed = false
    @State private var inputMethodNames: [String: String]  = [:]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General Preferences").font(.headline)) {
                    Toggle("Start at login", isOn: $startAtLogin)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                    Toggle("Silent start", isOn: $silentStart)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                    Toggle("Debug mode", isOn: $debugMode)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                    Toggle("Status icon", isOn: $showStatusBarIcon)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                }
                .padding(.horizontal, 10)
                
                Section(header: Text("Language Preferences").font(.headline)) {
                    Picker("Select Language", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("Chinese").tag("zh")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 3)
                    .padding(.horizontal, 20)
                    .onChange(of: selectedLanguage) { newValue in
                        changeLanguage(to: newValue)
                    }
                    .alert(isPresented: $showLanguageAlert) {
                        Alert(
                            title: Text("Language Changed"),
                            message: Text("Please restart the app for the language change to take effect."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .padding(.horizontal, 10)

                Section(header: Text("Runtime").font(.headline)) {
                    Picker("Default input method", selection: Binding(
                        get: {
                            return defaultInputSourceName
                        },
                        set: { (newValue: String) in
                            UserDefaults.standard.set(newValue, forKey: "defaultInputSourceName")
                        }
                    )) {
                        if !debugMode {
                            ForEach(recognizedInputSources, id: \.self) { inputSource in
                                let name = inputMethodNames[getInputMethodName(inputSource)] ??
                                ("Unrecognized: " + getInputMethodName(inputSource))
                                Text(name)
                                    .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                            }
                            Text("None")
                                .tag("None")
                        } else {
                            ForEach(recognizedInputSources, id: \.self) { inputSource in
                                let name = inputMethodNames[getInputMethodName(inputSource)] ??
                                ("Unrecognized: " + getInputMethodName(inputSource))
                                Text(name)
                                    .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                            }
                            ForEach(inputSources, id: \.self) { inputSource in
                                if !recognizedInputSources.contains(inputSource) {
                                    let name = inputMethodNames[getInputMethodName(inputSource)] ??
                                    ("Unrecognized: " + getInputMethodName(inputSource))
                                    Text(name)
                                        .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                                }
                            }
                            Text("None")
                                .tag("None")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 1)
                    .padding(.horizontal, 20)
                    
                    HStack(alignment: .center) {
                        Button("Reset preferences") {
                            showAlert = true
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Confirm Reset"),
                                message: Text("Are you sure you want to reset preferences to default?"),
                                primaryButton: .destructive(Text("Reset")) {
                                    resetSettings()
                                },
                                secondaryButton: .cancel()
                            )
                        };

                        Button("Quit app") {
                            NSApplication.shared.terminate(nil)
                        }
                    }
                    .padding(.vertical, 1)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 10)
                
                Section(header: Text("Contact").font(.headline)) {
                    Button("About") {
                        if let url = URL(string: "https://github.com/JimZhouZZY/MacAIM") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .padding(.vertical, 1)
                    .padding(.horizontal, 20)
                    Button("Report Issues") {
                        if let url = URL(string: "https://github.com/JimZhouZZY/MacAIM/issues") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .padding(.vertical, 1)
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 10)

                Section {
                    VStack(alignment: .center) {
                        Text("MacAIM Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Jim Zhou - jimzhouzzy@gmail.com")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Settings")
            .frame(width: 360, height: 450)
            .fixedSize()
        }
        .frame(width: 360, height: 450)
        .fixedSize()
        .onAppear {
            getAllInputSourceNames()
            getRecognizedInputSources()  // This triggers when the view appears
        }
    }
    
    func getInputMethodName(_ inputSource: TISInputSource) -> String {
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let inputSourceIDString = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return inputSourceIDString
        }
        return "Unknown"
    }
    
    func getRecognizedInputSources() {
        recognizedInputSources.removeAll() // Avoid repeatedly adding
        for inputSource in inputSources {
            if inputMethodNames[getInputMethodName(inputSource)] != nil {
                recognizedInputSources.append(inputSource)
            }
        }
    }
    
    func resetSettings() {
        do {
            print("Using default settings")
            UserDefaults.standard.set(false, forKey: "useDefault")
            UserDefaults.standard.set(false, forKey: "silentStart")
            UserDefaults.standard.set(false, forKey: "startAtLogin")
            UserDefaults.standard.set(false, forKey: "debugMode")
            UserDefaults.standard.set(true, forKey: "showStatusBarIcon")
            UserDefaults.standard.set("None", forKey: "defaultInputSourceName")
            UserDefaults.standard.set(false, forKey: "_showDashboard")
            UserDefaults.standard.set(false, forKey: "_showStatusBarIcon")
            UserDefaults.standard.set(false, forKey: "_hideStatusBarIcon")
            UserDefaults.standard.set(false, forKey: "_updateMenuState")
            UserDefaults.standard.set(false, forKey: "_clean")
            var saveDict: [String: String] = [:]
            let fileManager = FileManager.default
            var apps: [String] = []
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
    
    func changeLanguage(to language: String) {
        // Update the language setting
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        showLanguageAlert = true
    }
    
    func getAllInputSourceNames() {
        // Iterate over all input sources
        for inputSource in inputSources {
            // Get the localized name of the input source
            if let localizedName = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
                // It is hard to search for this line ...
                if let name = Unmanaged<CFString>.fromOpaque(localizedName).takeUnretainedValue() as String? {
                    //print(name)
                    if let cateptr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceCategory) {
                        if let category = Unmanaged<CFString>.fromOpaque(cateptr).takeUnretainedValue() as String? {
                            //print(category)
                            if category == "TISCategoryKeyboardInputSource"{
                                inputMethodNames[getInputMethodName(inputSource)] = name
                            }
                        }
                    }
                }
            }
        }
    }
}
