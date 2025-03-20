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
            }
            .navigationTitle("Settings")
            .frame(width: 320, height: 320)
            .fixedSize()
        }
        .frame(width: 320, height: 320)
        .fixedSize()
    }
}
