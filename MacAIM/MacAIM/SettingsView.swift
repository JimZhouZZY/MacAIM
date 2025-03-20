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
                    Toggle("Silent start", isOn: $silentStart)
                    Toggle("Debug mode", isOn: $debugMode)
                    Toggle("Status icon", isOn: $showStatusBarIcon)
                }
                .padding(.horizontal, 10) // 调整左右间距
                
                //Section {
                //    Button("Close") {
                //        NSApp.keyWindow?.close()
                //    }
                //    .frame(maxWidth: .infinity, alignment: .center)
                //    .padding(.vertical, 0)
                //}
            }
            .navigationTitle("Settings")
            .frame(width: 320, height: 250)
            .frame(width: 320, height: 250)
            .fixedSize() // fix window size
        }
    }
}
