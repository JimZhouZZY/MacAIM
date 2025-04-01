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

    You should have received a copy  of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation
import AppKit
import SwiftUI
import SwiftData
import Foundation
import Carbon
import AppKit
import Cocoa

let useDefaultKey = "useDefault"
let startAtLoginKey = "startAtLogin"
let silentStartKey = "silentStart"
let debugModeKey = "debugMode"
let showStatusBarIconKey = "showStatusBarIcon"
let defaultInputSourceNameKey = "defaultInputSourceName"
let selectedLanguageKey = "selectedLanguage"
let action_showDashboardKey = "action_showDashboard"
let action_showStatusBarIconKey = "action_showStatusBarIcon"
let action_hideStatusBarIconKey = "action_hideStatusBarIcon"
let action_updateMenuStateKey = "action_updateMenuState"
let action_cleanKey = "action_clean"
let appNameToInputSourceKey = "appNameToInputSource"

class Config: ObservableObject {
    static let shared = Config()
     
    @AppStorage(useDefaultKey) var useDefault = false
    @AppStorage(startAtLoginKey) var startAtLogin = false
    @AppStorage(silentStartKey) var silentStart = false
    @AppStorage(debugModeKey) var debugMode = false
    @AppStorage(showStatusBarIconKey) var showStatusBarIcon = true
    @AppStorage(defaultInputSourceNameKey) var defaultInputSourceName = "None"
    @AppStorage(selectedLanguageKey) var selectedLanguage = Locale.preferredLanguages.first ?? "en"
    @AppStorage(appNameToInputSourceKey) var appNameToInputSource = initAppNameToInputSource()
    @AppStorage(action_showDashboardKey) var action_showDashboard = false
    @AppStorage(action_showStatusBarIconKey) var action_showStatusBarIcon = false
    @AppStorage(action_hideStatusBarIconKey) var action_hideStatusBarIcon = false
    @AppStorage(action_updateMenuStateKey) var action_updateMenuState = false
    @AppStorage(action_cleanKey) var action_clean = false
    
    func reset() {
        useDefault = false
        startAtLogin = false
        silentStart = false
        debugMode = false
        showStatusBarIcon = true
        defaultInputSourceName = "None"
        selectedLanguage = "en"
        appNameToInputSource = initAppNameToInputSource()
        action_showDashboard = false
        action_showStatusBarIcon = false
        action_hideStatusBarIcon = false
        action_updateMenuState = false
        action_clean = false
    }
    
    func changeLanguage(to language: String) {
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}

// TODO: refactor this partly duplicated function
func initAppNameToInputSource() -> Data {
    var saveDict: [String: String] = [:]
    var apps: [String] = []
    let fileManager = FileManager.default
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
    var data = Data()
    do {
        data = try encoder.encode(saveDict)
    } catch {
        print("Error defaulting input source for applications: \(error)")
    }
    return data
}

var inputSourceManager: InputSourceManager = InputSourceManager()
