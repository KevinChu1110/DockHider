import SwiftUI
import AppKit

@main
struct DockHiderApp: App {
    // 將 App 設為附屬模式，確保其本體不顯示在 Dock
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    @StateObject private var appManager = AppManager()

    var body: some Scene {
        // 使用 .window 樣式，支援彈窗與更豐富的互動
        MenuBarExtra("DockHider", systemImage: "dock.arrow.up.rectangle") {
            AppMenuView(manager: appManager)
                .frame(width: 250) // 固定寬度，使其看起來像選單
        }
        .menuBarExtraStyle(.window)
    }
}
