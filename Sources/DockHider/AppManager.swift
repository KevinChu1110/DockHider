import Foundation
import AppKit

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
    let path: URL
    var isHiddenInDock: Bool
    var isRunning: Bool
    var shortcutDisplay: String? // 用於顯示，如 "⌘⌥S"
}

@MainActor
class AppManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var showRestartAlert = false
    @Published var lastModifiedApp: AppInfo?
    
    private var globalMonitor: Any?
    private let manualPathsKey = "ManualAppPaths"
    private let userHiddenAppsKey = "UserHiddenApps"
    private let shortcutsDataKey = "AppShortcutsData"
    
    init() {
        refreshApps()
        setupGlobalShortcut()
    }
    
    private func setupGlobalShortcut() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleGlobalKeyDown(event)
            }
        }
    }
    
    private func handleGlobalKeyDown(_ event: NSEvent) {
        let shortcuts = UserDefaults.standard.dictionary(forKey: shortcutsDataKey) as? [String: [UInt64]] ?? [:]
        let currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let currentKeyCode = event.keyCode
        
        for (bundleID, data) in shortcuts {
            if data.count == 2 && data[0] == UInt64(currentModifiers) && data[1] == UInt64(currentKeyCode) {
                activateApp(bundleID: bundleID)
                break
            }
        }
    }
    
    func saveShortcut(for bundleID: String, event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let keyCode = event.keyCode
        
        var shortcuts = UserDefaults.standard.dictionary(forKey: shortcutsDataKey) as? [String: [UInt64]] ?? [:]
        shortcuts[bundleID] = [UInt64(modifiers), UInt64(keyCode)]
        UserDefaults.standard.set(shortcuts, forKey: shortcutsDataKey)
        
        refreshApps()
    }
    
    func clearShortcut(for bundleID: String) {
        var shortcuts = UserDefaults.standard.dictionary(forKey: shortcutsDataKey) as? [String: [UInt64]] ?? [:]
        shortcuts.removeValue(forKey: bundleID)
        UserDefaults.standard.set(shortcuts, forKey: shortcutsDataKey)
        refreshApps()
    }
    
    func getShortcutDisplay(bundleID: String) -> String? {
        let shortcuts = UserDefaults.standard.dictionary(forKey: shortcutsDataKey) as? [String: [UInt64]] ?? [:]
        guard let data = shortcuts[bundleID], data.count == 2 else { return nil }
        
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(data[0]))
        let keyCode = UInt16(data[1])
        
        var display = ""
        if modifiers.contains(.control) { display += "⌃" }
        if modifiers.contains(.option) { display += "⌥" }
        if modifiers.contains(.shift) { display += "⇧" }
        if modifiers.contains(.command) { display += "⌘" }
        
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            49: "Space", 51: "Delete", 53: "Esc", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        display += keyMap[keyCode] ?? "K\(keyCode)"
        
        return display
    }
    
    func refreshApps() {
        let userHiddenList = UserDefaults.standard.stringArray(forKey: userHiddenAppsKey) ?? []
        let manualPaths = UserDefaults.standard.stringArray(forKey: manualPathsKey) ?? []
        
        var allAppsMap: [String: AppInfo] = [:]
        for path in manualPaths {
            if let app = getAppInfo(from: URL(fileURLWithPath: path)) {
                allAppsMap[app.id] = app
            }
        }
        for app in scanApplications() {
            if allAppsMap[app.id] == nil {
                allAppsMap[app.id] = app
            }
        }
        
        self.apps = allAppsMap.values.filter { app in
            userHiddenList.contains(app.id)
        }.map { app in
            var mutableApp = app
            mutableApp.shortcutDisplay = getShortcutDisplay(bundleID: app.id)
            return mutableApp
        }.sorted { $0.name < $1.name }
    }
    
    private func fetchBestIcon(for path: URL) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: path.path)
        icon.isTemplate = false
        
        let size = NSSize(width: 64, height: 64)
        let offscreenRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                          pixelsWide: Int(size.width),
                                          pixelsHigh: Int(size.height),
                                          bitsPerSample: 8,
                                          samplesPerPixel: 4,
                                          hasAlpha: true,
                                          isPlanar: false,
                                          colorSpaceName: .deviceRGB,
                                          bytesPerRow: 0,
                                          bitsPerPixel: 0)
        
        if let rep = offscreenRep {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            icon.draw(in: NSRect(origin: .zero, size: size))
            NSGraphicsContext.restoreGraphicsState()
            
            let newImage = NSImage(size: size)
            newImage.addRepresentation(rep)
            newImage.isTemplate = false
            return newImage
        }
        
        return icon
    }
    
    private func getAppInfo(from url: URL) -> AppInfo? {
        guard url.pathExtension == "app" else { return nil }
        let name = url.deletingPathExtension().lastPathComponent
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return nil }
        
        let icon = fetchBestIcon(for: url)
        let isHidden = checkIfHiddenInPlist(path: url)
        
        return AppInfo(
            id: bundleID,
            name: name,
            icon: icon,
            path: url,
            isHiddenInDock: isHidden,
            isRunning: NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bundleID }),
            shortcutDisplay: nil
        )
    }
    
    func scanApplications() -> [AppInfo] {
        let fileManager = FileManager.default
        let appDirectories = [
            URL(fileURLWithPath: "/Applications"),
            fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first
        ].compactMap { $0 }
        
        var allApps: [AppInfo] = []
        let excludeKeywords = ["helper", "agent", "plugin", "service", "overlay", "notification", "renderer", "crashpad", "uiserver", "uagent"]
        
        for directory in appDirectories {
            let enumerator = fileManager.enumerator(at: directory, 
                                                  includingPropertiesForKeys: [.isApplicationKey], 
                                                  options: [.skipsPackageDescendants, .skipsHiddenFiles])
            
            while let url = enumerator?.nextObject() as? URL {
                guard url.pathExtension == "app" else { continue }
                let name = url.deletingPathExtension().lastPathComponent
                let lowerName = name.lowercased()
                if excludeKeywords.contains(where: { lowerName.contains($0) }) { continue }
                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier else { continue }
                if bundleID == Bundle.main.bundleIdentifier { continue }
                if bundle.infoDictionary?["CFBundleExecutable"] == nil { continue }
                
                let icon = fetchBestIcon(for: url)
                
                allApps.append(AppInfo(
                    id: bundleID,
                    name: name,
                    icon: icon,
                    path: url,
                    isHiddenInDock: checkIfHiddenInPlist(path: url),
                    isRunning: NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bundleID }),
                    shortcutDisplay: nil
                ))
                enumerator?.skipDescendants()
            }
        }
        return allApps
    }
    
    private func checkIfHiddenInPlist(path: URL) -> Bool {
        let plistURL = path.appendingPathComponent("Contents/Info.plist")
        guard let plist = NSDictionary(contentsOf: plistURL) else { return false }
        return plist["LSUIElement"] as? Bool ?? (plist["LSUIElement"] as? String == "1")
    }
    
    func toggleDockVisibility(for app: AppInfo) {
        let plistURL = app.path.appendingPathComponent("Contents/Info.plist")
        guard let plistData = try? Data(contentsOf: plistURL),
              var plist = try? PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            return
        }
        let newVisibility = !app.isHiddenInDock
        plist["LSUIElement"] = newVisibility
        do {
            let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try updatedData.write(to: plistURL, options: .atomic)
            reSignApp(at: app.path)
            
            var list = UserDefaults.standard.stringArray(forKey: userHiddenAppsKey) ?? []
            if newVisibility {
                if !list.contains(app.id) { list.append(app.id) }
                if !app.path.path.contains("/Applications") {
                    var paths = UserDefaults.standard.stringArray(forKey: manualPathsKey) ?? []
                    if !paths.contains(app.path.path) { paths.append(app.path.path) }
                    UserDefaults.standard.set(paths, forKey: manualPathsKey)
                }
            } else {
                list.removeAll { $0 == app.id }
            }
            UserDefaults.standard.set(list, forKey: userHiddenAppsKey)
            self.showRestartAlert = true
            refreshApps()
        } catch {
            print("寫入失敗: \(error)")
        }
    }
    
    func handleManualSelection(url: URL) {
        if let app = getAppInfo(from: url) {
            var paths = UserDefaults.standard.stringArray(forKey: manualPathsKey) ?? []
            if !paths.contains(url.path) {
                paths.append(url.path)
                UserDefaults.standard.set(paths, forKey: manualPathsKey)
            }
            var list = UserDefaults.standard.stringArray(forKey: userHiddenAppsKey) ?? []
            if !list.contains(app.id) { list.append(app.id) }
            UserDefaults.standard.set(list, forKey: userHiddenAppsKey)
            toggleDockVisibility(for: app)
        }
    }
    
    private func reSignApp(at path: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-f", "-s", "-", "--deep", path.path]
        try? process.run()
        process.waitUntilExit()
    }
    
    func restartApp(_ app: AppInfo) {
        let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.id })
        if let runningApp = runningApp {
            runningApp.terminate()
            DispatchQueue.global().async {
                var retryCount = 0
                while NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == app.id }) && retryCount < 20 {
                    Thread.sleep(forTimeInterval: 0.5)
                    retryCount += 1
                }
                DispatchQueue.main.async { self.openApp(at: app.path) }
            }
        } else {
            self.openApp(at: app.path)
        }
    }
    
    private func openApp(at path: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [path.path]
        try? process.run()
    }
    
    func activateApp(bundleID: String) {
        let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID })
        
        guard let app = runningApp else {
            print("App 未在執行中，嘗試啟動...")
            // 如果沒在跑，才執行 AppleScript activate (這會啟動它)
            let script = "tell application id \"\(bundleID)\" to activate"
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(nil)
            }
            return
        }
        
        // 如果已經在跑，執行純粹的視窗切換
        print("App 執行中，嘗試喚醒視窗...")
        app.unhide()
        app.activate(options: [.activateAllWindows])
        
        // 輔助腳本：僅設為最前景，不呼叫 reopen
        let script = """
        tell application "System Events"
            set frontmost of process id \(app.processIdentifier) to true
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
}
