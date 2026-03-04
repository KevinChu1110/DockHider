# DockHider 🚀

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Donate-orange?style=flat-square&logo=buy-me-a-coffee)](https://buymeacoffee.com/guanrung11n)

![DockHider Screenshot](screenshot.png)

[繁體中文](#繁體中文) | [English](#english)

---

## 繁體中文

**DockHider** 是一款專為 macOS 設計的輕量化選單列工具。它可以讓您隱藏特定應用程式在 Dock 上的圖示，讓您的工作列保持簡潔，同時依然保留快速喚醒的功能。

### ✨ 核心功能
- **隱藏 Dock 圖示**：修改 App 設定使圖示不顯示在 Dock 上。
- **一鍵喚醒**：即使 App 隱藏了，透過選單列圖示點擊即可快速跳轉。
- **全域快捷鍵**：按下 `Cmd + Shift + H` 立即喚醒隱藏中的 App。
- **自動重啟**：變更隱藏設定時，DockHider 會詢問並協助您重啟 App 以立即生效。
- **開機自啟動**：隨 macOS 登入自動執行。

### 📥 安裝方式 (Homebrew)
如果你已經建立了 Tap，可以使用以下指令安裝：
```bash
brew install --cask KevinChu1110/tap/dockhider
```

### 📖 使用提示
1. **第一次設定**：選取 App 點擊「從 Dock 隱藏」後，系統會要求重啟該 App。
2. **喚醒 App**：您可以點擊螢幕上方選單列的 📥 圖示，或使用快捷鍵 `⌘ + ⇧ + H`。
3. **重要說明**：由於此工具會修改 App 內部的 `Info.plist` 設定，建議僅用於非系統內建的應用程式。

### ☕️ 支持開發者
如果您覺得這個工具對您有幫助，歡迎請我喝杯咖啡，您的支持是我持續更新的動力！
👉 [Buy Me a Coffee](https://buymeacoffee.com/guanrung11n)

---

## English

**DockHider** is a lightweight macOS menu bar utility designed to declutter your workspace. It allows you to hide specific application icons from the Dock while keeping them easily accessible.

### ✨ Features
- **Hide Dock Icons**: Toggle `LSUIElement` setting to make icons disappear from the Dock.
- **Quick Access**: Access and focus your hidden apps directly from the Menu Bar.
- **Global Shortcut**: Press `Cmd + Shift + H` to bring hidden apps to the front instantly.
- **Auto-Restart**: Guided restart flow to apply visibility settings immediately.
- **Launch at Login**: Optional setting to start DockHider when you log in.

### 📥 Installation (Homebrew)
```bash
brew install --cask KevinChu1110/tap/dockhider
```

### 📖 Usage Tips
1. **Initial Setup**: When you hide an app for the first time, click "Restart Now" to apply changes.
2. **Wake up Apps**: Click the 📥 icon in the Menu Bar or use the shortcut `⌘ + ⇧ + H`.
3. **Note**: This utility modifies the `Info.plist` of the target application. It is recommended for third-party apps.

### ☕️ Support the Developer
If you find this tool useful, feel free to buy me a coffee. Your support is greatly appreciated!
👉 [Buy Me a Coffee](https://buymeacoffee.com/guanrung11n)

---

## License
Distributed under the MIT License. See `LICENSE` for more information.

---
*Created with ❤️ by [KevinChu1110](https://github.com/KevinChu1110)*
