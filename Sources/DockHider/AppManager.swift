import Foundation
import AppKit

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
    let path: URL
    var isHiddenInDock: Bool
    var isRunning: Bool
}

@MainActor
class AppManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var showRestartAlert = false
    @Published var lastModifiedApp: AppInfo?
    
    private var eventMonitor: Any?
    
    init() {
        refreshApps()
        setupNativeShortcut()
    }
    
    private func setupNativeShortcut() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .shift] && event.keyCode == 4 {
                Task { @MainActor in
                    self.wakeUpFirstHiddenApp()
                }
            }
        }
    }
    
    func wakeUpFirstHiddenApp() {
        if let target = apps.first(where: { $0.isHiddenInDock }) {
            activateApp(bundleID: target.id)
        }
    }
    
    func refreshApps() {
        let runningApps = NSWorkspace.shared.runningApplications
        let filteredApps = runningApps.filter { $0.activationPolicy == .regular }
        
        self.apps = filteredApps.compactMap { app in
            guard let bundleID = app.bundleIdentifier, 
                  let name = app.localizedName,
                  let path = app.bundleURL else { return nil }
            
            return AppInfo(
                id: bundleID,
                name: name,
                icon: app.icon,
                path: path,
                isHiddenInDock: checkIfHiddenInPlist(path: path),
                isRunning: true
            )
        }
    }
    
    private func checkIfHiddenInPlist(path: URL) -> Bool {
        let plistURL = path.appendingPathComponent("Contents/Info.plist")
        guard let plist = NSDictionary(contentsOf: plistURL) else { return false }
        return plist["LSUIElement"] as? Bool ?? (plist["LSUIElement"] as? String == "1")
    }
    
    func toggleDockVisibility(for app: AppInfo) {
        let plistURL = app.path.appendingPathComponent("Contents/Info.plist")
        guard var plist = NSDictionary(contentsOf: plistURL) as? [String: Any] else { return }
        
        plist["LSUIElement"] = !app.isHiddenInDock
        (plist as NSDictionary).write(to: plistURL, atomically: true)
        
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].isHiddenInDock.toggle()
            self.lastModifiedApp = apps[index]
            self.showRestartAlert = true
        }
    }
    
    func restartApp(_ app: AppInfo) {
        print("開始重啟流程: \(app.name)")
        let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.id })
        
        if let runningApp = runningApp {
            print("正在結束 App: \(app.id)")
            runningApp.terminate()
            
            DispatchQueue.global().async {
                var retryCount = 0
                while NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == app.id }) && retryCount < 20 {
                    Thread.sleep(forTimeInterval: 0.5)
                    retryCount += 1
                }
                
                print("App 已關閉，嘗試重新開啟...")
                self.openApp(at: app.path)
            }
        } else {
            print("App 未在執行，直接開啟...")
            self.openApp(at: app.path)
        }
    }
    
    private func openApp(at path: URL) {
        // 使用 shell command 'open' 是最穩定的方式
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [path.path]
        
        do {
            try process.run()
            print("已執行 open 指令")
        } catch {
            print("執行 open 指令失敗: \(error.localizedDescription)")
        }
    }
    
    func activateApp(bundleID: String) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            app.activate(options: [.activateAllWindows])
        }
    }
}
