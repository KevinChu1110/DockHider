# DockHider 🚀

[繁體中文](#繁體中文) | [English](#english)

---

## 繁體中文

**DockHider** 是一款專為 macOS 設計的選單列小工具，讓您可以輕鬆隱藏 Dock 上的應用程式圖示，保持工作空間整潔，同時依然能快速切換與喚醒這些 App。

### ✨ 核心特色
- **隱藏 Dock 圖示**：一鍵修改 App 設定，讓圖示從 Dock 消失。
- **選單列管理**：即使 App 隱藏了，仍可透過螢幕上方的選單列點擊喚醒。
- **全域快捷鍵**：預設使用 `Cmd + Shift + H` 快速將隱藏的 App 喚醒至最前景。
- **自動重啟支援**：修改設定後可選擇自動重啟該 App，省去手動操作。
- **開機自啟動**：支援設定登入後自動執行。

### 🚀 安裝方式 (Homebrew)
*即將推出...*

### 🛠️ 開發與編譯
如果你想自行編譯：
1. 下載此 Repo。
2. 執行 `./package_app.sh` 進行打包。
3. 在根目錄會產出 `DockHider.app`。

---

## English

**DockHider** is a macOS menu bar utility that allows you to hide application icons from your Dock to keep your workspace clean, while still providing quick access to them.

### ✨ Features
- **Hide Dock Icons**: Toggle `LSUIElement` setting for any running app with one click.
- **Menu Bar Access**: Quickly wake up hidden apps from the system menu bar.
- **Global Shortcut**: Press `Cmd + Shift + H` to bring the first hidden app to the front.
- **Auto-Restart**: Support for automatically restarting apps after settings changed.
- **Launch at Login**: Optional setting to start DockHider when you log in.

### 🚀 Installation (Homebrew)
*Coming soon...*

### 🛠️ Build from Source
1. Clone this repository.
2. Run `./package_app.sh` to build the app bundle.
3. Find `DockHider.app` in the root directory.

---

## License
MIT License. Feel free to use and contribute!
