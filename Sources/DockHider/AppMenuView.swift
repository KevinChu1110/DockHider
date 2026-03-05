import SwiftUI
import AppKit

struct AppMenuView: View {
    @ObservedObject var manager: AppManager
    @State private var settings = SettingsManager.shared
    @State private var showPicker = false
    @State private var runningApps: [AppInfo] = []
    @State private var searchText = ""
    
    // 快捷鍵錄製狀態 (改為內嵌顯示)
    @State private var recordingApp: AppInfo? = nil
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                if manager.apps.isEmpty && !showPicker {
                    Text("目前沒有已隱藏的 App")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else if !manager.apps.isEmpty {
                    Text("已隱藏的應用程式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    
                    Divider()
                    
                    ForEach(manager.apps) { app in
                        HStack(spacing: 0) {
                            Button(action: {
                                manager.activateApp(bundleID: app.id)
                            }) {
                                HStack {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .renderingMode(.original)
                                            .resizable()
                                            .frame(width: 18, height: 18)
                                    }

                                    Text(app.name)
                                    Spacer()
                                    if let display = app.shortcutDisplay {
                                        Text(display)
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            
                            Menu {
                                Button("設定快捷鍵...") {
                                    withAnimation { recordingApp = app }
                                }
                                if app.shortcutDisplay != nil {
                                    Button("清除快捷鍵") {
                                        manager.clearShortcut(for: app.id)
                                    }
                                }
                                Divider()
                                Button("恢復到 Dock") {
                                    manager.toggleDockVisibility(for: app)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.secondary)
                            }
                            .menuStyle(.button)
                            .frame(width: 30)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                
                Divider()
                
                // 操作按鈕區
                VStack(spacing: 4) {
                    Button(action: {
                        if !showPicker {
                            runningApps = manager.scanApplications()
                        }
                        showPicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: showPicker ? "chevron.up" : "plus.circle.fill")
                            Text(showPicker ? "關閉挑選器" : "挑選 App 隱藏...")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if showPicker {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("搜尋應用程式...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal, 8)
                            
                            ScrollView {
                                VStack(spacing: 0) {
                                    let filtered = runningApps.filter { 
                                        searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                                    }
                                    ForEach(filtered) { app in
                                        Button(action: {
                                            manager.toggleDockVisibility(for: app)
                                            showPicker = false
                                            searchText = ""
                                        }) {
                                            HStack {
                                                if let icon = app.icon {
                                                    Image(nsImage: icon)
                                                        .resizable()
                                                        .frame(width: 14, height: 14)
                                                }
                                                Text(app.name)
                                                    .font(.subheadline)
                                                Spacer()
                                                if app.isHiddenInDock {
                                                    Image(systemName: "eye.slash.fill")
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                            .padding(.horizontal, 8)
                            
                            Divider().padding(.horizontal)
                            
                            Button(action: { selectFileManually() }) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("手動選擇 App 檔案 (.app)...").font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 8)
                    }
                }
                
                Divider()
                
                // 設定區
                Group {
                    Button("設定權限 (如遇阻擋)") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("重新整理列表") { manager.refreshApps() }
                    Button("結束 DockHider") { NSApplication.shared.terminate(nil) }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .blur(radius: recordingApp != nil ? 5 : 0)
            .disabled(recordingApp != nil)
            
            // 內嵌錄製介面
            if let app = recordingApp {
                Color.black.opacity(0.1)
                    .onTapGesture { recordingApp = nil }
                
                ShortcutRecorderView(app: app) { event in
                    manager.saveShortcut(for: app.id, event: event)
                    withAnimation { recordingApp = nil }
                } onCancel: {
                    withAnimation { recordingApp = nil }
                }
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 10)
                .padding(20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 250)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .onChange(of: manager.showRestartAlert) { oldValue, newValue in
            if newValue, let app = manager.lastModifiedApp {
                showNativeAlert(app: app)
                manager.showRestartAlert = false
            }
        }
    }
    
    private func selectFileManually() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.message = "請選擇您要隱藏/恢復的應用程式 (.app)"
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            manager.handleManualSelection(url: url)
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
        if response == .alertFirstButtonReturn { manager.restartApp(app) }
    }
}

struct ShortcutRecorderView: View {
    let app: AppInfo
    let onRecord: (NSEvent) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            
            Text("設定快捷鍵")
                .font(.headline)
            
            Text("請直接按下您想要的組合鍵\n(例如 Option + S)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    .frame(height: 50)
                
                Text("等待按鍵中...")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            Button("取消") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(KeyCaptureView(onCapture: onRecord))
    }
}

struct KeyCaptureView: NSViewRepresentable {
    let onCapture: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }
    
    class Coordinator: NSObject {
        var onCapture: (NSEvent) -> Void
        var monitor: Any?
        
        init(onCapture: @escaping (NSEvent) -> Void) {
            self.onCapture = onCapture
            super.init()
            self.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.onCapture(event)
                return nil
            }
        }
        
        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}
