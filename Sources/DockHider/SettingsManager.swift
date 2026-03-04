import Foundation
import ServiceManagement
import Observation

@MainActor
@Observable
class SettingsManager {
    static let shared = SettingsManager()
    
    var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("設定登入啟動失敗: \(error.localizedDescription)")
            }
        }
    }
}
