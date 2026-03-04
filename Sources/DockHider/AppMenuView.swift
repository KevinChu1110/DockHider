import SwiftUI
import AppKit

struct AppMenuView: View {
    @ObservedObject var manager: AppManager
    @State private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("執行中的應用程式")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 4)
            
            Divider()
            
            ForEach(manager.apps) { app in
                Button(action: {
                    manager.activateApp(bundleID: app.id)
                }) {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        Text(app.name)
                        Spacer()
                        if app.isHiddenInDock {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Menu {
                    Button(app.isHiddenInDock ? "恢復到 Dock" : "從 Dock 隱藏") {
                        manager.toggleDockVisibility(for: app)
                    }
                } label: {
                    Text("設定...")
                }
            }
            
            Divider()
            
            Text("全域設定")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 4)
            
            HStack {
                Text("喚醒快捷鍵 (固定):")
                Spacer()
                Text("⌘ + ⇧ + H")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            Toggle("開機自動啟動", isOn: Bindable(settings).launchAtLogin)
                .padding(.horizontal)
                .padding(.vertical, 4)

            Divider()
            
            Button("重新整理列表") {
                manager.refreshApps()
            }
            
            Divider()
            
            Button("☕️ 支持開發者") {
                if let url = URL(string: "https://buymeacoffee.com/guanrung11n") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("結束 DockHider") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: manager.showRestartAlert) { oldValue, newValue in
            if newValue, let app = manager.lastModifiedApp {
                showNativeAlert(app: app)
                manager.showRestartAlert = false
            }
        }
    }
    
    private func showNativeAlert(app: AppInfo) {
        let alert = NSAlert()
        alert.messageText = "套用隱藏設定"
        alert.informativeText = "必須重啟 「\(app.name)」 設定才會生效。是否現在為您自動重啟？"
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: "立即重啟")
        alert.addButton(withTitle: "稍後手動")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            manager.restartApp(app)
        }
    }
}
