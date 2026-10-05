#!/bin/bash
set -e

APP_NAME="CloudflareSwitcher"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Building release binary..."
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/${APP_NAME}"

echo "📦 Creating app bundle: ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${RELEASE_BIN}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>CloudflareSwitcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.CloudflareSwitcher</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Cloudflare Switcher</string>
    <key>CFBundleDisplayName</key>
    <string>Cloudflare Switcher</string>
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
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

# Ad-hoc code sign agar macOS Gatekeeper tidak memblokir binary lokal
echo "🔏 Signing application bundle (ad-hoc)..."
codesign --force --deep --sign - "${APP_DIR}"

echo "✅ App bundle created successfully: ${APP_DIR}"
echo "🚀 Jalankan aplikasi dengan: open ${APP_DIR}"
