#!/bin/bash

# 設定變數
APP_NAME="DockHider"
BUNDLE_ID="com.kevinchu.DockHider"
BUILD_DIR=".build/arm64-apple-macosx/release"
APP_BUNDLE="$APP_NAME.app"

echo "🚀 開始編譯 Release 版本..."
swift build -c release --arch arm64

# 建立 .app 結構
echo "📦 封裝 $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 複製執行檔
cp ".build/arm64-apple-macosx/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 建立 Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ 打包完成：$APP_BUNDLE"
echo "🛠️ 提示：之後您可以將其壓縮成 $APP_NAME.zip 並上傳到 GitHub Release。"
