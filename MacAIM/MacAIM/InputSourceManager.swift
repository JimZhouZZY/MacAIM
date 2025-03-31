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

public class InputSourceManager {
    @AppStorage("debugMode") var debugMode: Bool = false
    @AppStorage("defaultInputSourceName") private var defaultInputSourceName = "None"
    
    public var apps: [String] = []
    public var defaultInputSource: TISInputSource? = nil
    public var currentAppName: String? = nil
    public var appNameToInputSource: [String: TISInputSource?] = [:]
    public var appAddedDates: [String: Date] = [:]
    public var isReversed: Bool = false // Is sorting result reverted
    public var inputSources = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    public var recognizedInputSources = TISCreateInputSourceList(nil, false)
                                                    .takeRetainedValue() as! [TISInputSource]
    public var appNameToBundleIdentifier: [String: String] = [:]
    public var bundleIdentifierToAppName: [String: String] = [:]
    public var intputSourceBundleNameToName: [String: String] = [:]
    public var lastAppBundleIdentifier = ""
    
    init() {
        self.getAllInputSourceNames()
        self.loadApplications()
        self.loadInputSources()
        self.getRecognizedInputSources()
        self.mainLoop()
    }
    
    func getRecognizedInputSources() {
        recognizedInputSources.removeAll() // Avoid repeatedly adding
        for inputSource in inputSources {
            if intputSourceBundleNameToName[getInputSourceBundleNameFromInputSource(inputSource)] != nil {
                recognizedInputSources.append(inputSource)
            }
        }
    }
    
    func getInputSourceForAppName(_ appname: String) -> TISInputSource? {
        if let inputSource = appNameToInputSource[appname] {
            return inputSource
        }
        return nil
    }
    
    func getInputSourceNameFromInputSource(_ inputSource: TISInputSource) -> String? {
        return getInputSourceNameFromBundleName(getInputSourceBundleNameFromInputSource(inputSource))
    }
    
    func getInputSourceNameFromBundleName(_ bundleName: String) -> String? {
        return intputSourceBundleNameToName[bundleName]
    }
    
    func getInputSourceBundleNameFromInputSource(_ inputSource: TISInputSource) -> String {
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
                    let inputSourceID = getInputSourceBundleNameFromInputSource(inputSource)
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
    
    func loadInputSources() {
        if let savedData = UserDefaults.standard.data(forKey: "inputMethodToInputSource") {
            do {
                let decoder = JSONDecoder()
                let decodedDict = try decoder.decode([String: String].self, from: savedData)
                var restoredDict: [String: TISInputSource?] = [:]
                for (appName, inputSourceID) in decodedDict {
                    if let inputSource = inputSources.first(where: { getInputSourceBundleNameFromInputSource($0) == inputSourceID }) {
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
                    appAddedDates[appURL.deletingPathExtension().lastPathComponent] = creationDate
                }
            }
            apps = appURLs
                .filter { $0.pathExtension == "app" }
                .map { $0.deletingPathExtension().lastPathComponent }
            
            for appName in apps {
                let appPath = "/Applications/\(appName).app"
                if let bundle = Bundle(url: URL(fileURLWithPath: appPath)), let bundleIdentifier = bundle.bundleIdentifier {
                    appNameToBundleIdentifier[appName] = bundleIdentifier
                    bundleIdentifierToAppName[bundleIdentifier] = appName
                }
            }
        } catch {
            print("Error loading applications: \(error)")
        }
    }
    
    
    func switchInputSourceTo(_ inputSource: TISInputSource) {
        TISSelectInputSource(inputSource)
        return
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
                        if let category = Unmanaged<CFString>.fromOpaque(cateptr).takeUnretainedValue() as CFString? {
                            //print(category)
                            if category == kTISCategoryKeyboardInputSource {
                                if let typeptr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceType) {
                                    if let type = Unmanaged<CFString>.fromOpaque(typeptr).takeUnretainedValue() as CFString? {
                                        //print(name, type)
                                        if type != kTISTypeKeyboardInputMethodModeEnabled {
                                            intputSourceBundleNameToName[getInputSourceBundleNameFromInputSource(inputSource)] = name
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getCurrentAppName() -> (String, String) {
        let lastlastAppBundleIdentifier = lastAppBundleIdentifier
        if let frontApp = NSWorkspace.shared.menuBarOwningApplication {
            lastAppBundleIdentifier = frontApp.bundleIdentifier ?? ""
            return (lastAppBundleIdentifier, lastlastAppBundleIdentifier)
        }
        return ("", lastlastAppBundleIdentifier)
    }
    
    func mainLoop() {
        // This method is robust enough, I think
        // Run the loop in a background thread
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let retval: (String?, String?) = self.getCurrentAppName()
            let appBundleIdentidier = retval.0 ?? ""
            if appBundleIdentidier != "" {
                let lastAppBundleIdentidier = retval.1 ?? ""
                // Only trigger when the app name changes
                if !(appBundleIdentidier == lastAppBundleIdentidier) {
                    let appName = self.bundleIdentifierToAppName[appBundleIdentidier] ?? appBundleIdentidier
                    print("User is now using: \(appBundleIdentidier)")
                    if let inputSource = self.appNameToInputSource[appName] {
                        // Is this dispatch neccesarry?
                        DispatchQueue.main.async {
                            self.switchInputSourceTo(inputSource!)
                        }
                    } else if self.defaultInputSourceName != "None" {
                        // Ditto
                        DispatchQueue.main.async {
                            if let inputSource = self.inputSources.first(where: { self.getInputSourceNameFromInputSource($0) == self.defaultInputSourceName }) {
                                self.switchInputSourceTo(inputSource)
                            }
                        }
                    } else {
                        print("No input method found for \(appName)")
                    }
                }
            } else {
                print("Unable to get the current app name")
            }
        }
    }
}
