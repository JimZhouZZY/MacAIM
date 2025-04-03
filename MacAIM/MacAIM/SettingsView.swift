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
    @StateObject private var config = Config.shared
    
    @State private var showAlert = false
    @State private var showLanguageAlert = false
    @State private var resetConfirmed = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General Preferences").font(.headline)) {
                    Toggle("Start at login", isOn: config.$startAtLogin)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                    Toggle("Silent start", isOn: config.$silentStart)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                    Toggle("Debug mode", isOn: config.$debugMode)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                    Toggle("Status icon", isOn: config.$showStatusBarIcon)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 20)
                        .onChange(of: config.showStatusBarIcon) { newValue in
                            if config.showStatusBarIcon {
                                config.action_showStatusBarIcon = true
                            } else {
                                config.action_hideStatusBarIcon = true
                            }
                        }
                }
                .padding(.horizontal, 10)
                
                Section(header: Text("Language Preferences").font(.headline)) {
                    Picker("Select Language", selection: config.$selectedLanguage) {
                        Text("English").tag("en")
                        Text("Chinese").tag("zh")
                        Text("French").tag("fr")
                        // Text("DE").tag("de")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 3)
                    .padding(.horizontal, 20)
                    .onChange(of: config.selectedLanguage) { newValue in
                        config.changeLanguage(to: newValue)
                        showLanguageAlert = true
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
                            return config.defaultInputSourceName
                        },
                        set: { (newValue: String) in
                            config.defaultInputSourceName = newValue
                        }
                    )) {
                        if !config.debugMode {
                            ForEach(inputSourceManager.recognizedInputSources, id: \.self) { inputSource in
                                let name = inputSourceManager.getInputSourceNameFromInputSource(inputSource) ??
                                    ("Unrecognized: " + inputSourceManager.getInputSourceBundleNameFromInputSource(inputSource))
                                Text(name)
                                    .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                            }
                            Text("None")
                                .tag("None")
                        } else {
                            ForEach(inputSourceManager.recognizedInputSources, id: \.self) { inputSource in
                                let name = inputSourceManager.getInputSourceNameFromInputSource(inputSource) ??
                                    ("Unrecognized: " + inputSourceManager.getInputSourceBundleNameFromInputSource(inputSource))
                                Text(name)
                                    .tag(name.replacingOccurrences(of: "Unrecognized: ", with: ""))
                            }
                            ForEach(inputSourceManager.inputSources, id: \.self) { inputSource in
                                if !inputSourceManager.recognizedInputSources.contains(inputSource) {
                                    let name = inputSourceManager.getInputSourceNameFromInputSource(inputSource) ??
                                        ("Unrecognized: " + inputSourceManager.getInputSourceBundleNameFromInputSource(inputSource))
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
                                    config.reset()
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
        }
    }
}
