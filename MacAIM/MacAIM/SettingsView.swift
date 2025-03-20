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

struct SettingsView: View {
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("silentStart") private var silentStart = false
    @AppStorage("debugMode") private var debugMode = false
    @AppStorage("showStatusBarIcon") private var showStatusBarIcon = true

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General Preferences").font(.headline)) {
                    Toggle("Start at login", isOn: $startAtLogin)
                        .padding(.vertical, 3)
                    Toggle("Silent start", isOn: $silentStart)
                        .padding(.vertical, 3)
                    Toggle("Debug mode", isOn: $debugMode)
                        .padding(.vertical, 3)
                    Toggle("Status icon", isOn: $showStatusBarIcon)
                        .padding(.vertical, 3)
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
            .frame(width: 320, height: 340)
            .fixedSize()
        }
        .frame(width: 320, height: 340)
        .fixedSize()
    }
}
