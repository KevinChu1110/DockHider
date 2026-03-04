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
        // 使用 macOS 14+ 的 MenuBarExtra API
        MenuBarExtra("DockHider", systemImage: "dock.arrow.up.rectangle") {
            AppMenuView(manager: appManager)
        }
        .menuBarExtraStyle(.menu)
    }
}
