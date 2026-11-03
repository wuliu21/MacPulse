#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "🔨 [1/3] 正在编译 MacPulse Release 原生二进制..."
swift build -c release

APP_NAME="MacPulse.app"
CONTENTS_DIR="$PROJECT_DIR/$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 [2/3] 正在组装 $APP_NAME 应用包..."
rm -rf "$PROJECT_DIR/$APP_NAME"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$PROJECT_DIR/.build/release/MacPulse" "$MACOS_DIR/MacPulse"
chmod +x "$MACOS_DIR/MacPulse"

cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>MacPulse</string>
    <key>CFBundleIdentifier</key>
    <string>com.macpulse.hud</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacPulse</string>
    <key>CFBundleDisplayName</key>
    <string>MacPulse 性能监控</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "🔏 [3/3] 正在进行本地签名..."
codesign --force --deep --sign - "$PROJECT_DIR/$APP_NAME"

echo "✅ 构建完成: $PROJECT_DIR/$APP_NAME"
