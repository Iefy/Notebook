#!/usr/bin/env bash
#
# build-mac-app.sh
#
# Packages Notebook.html into a standalone native macOS application
# (Notebook.app) using a small Swift/WKWebView wrapper (main.swift) — a
# real app window, not a browser tab.
#
# Usage:
#   ./build-mac-app.sh
#
# Requires: macOS with Xcode Command Line Tools installed (provides swiftc,
# sips, iconutil). If you don't have them: xcode-select --install
#
# Run this from the repo root, alongside Notebook.html, icons/, and main.swift.
#
# Output: dist/Notebook.app  and  dist/Notebook-mac.zip

set -euo pipefail

APP_NAME="Notebook"
BUILD_DIR="dist"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "error: swiftc not found." >&2
  echo "Install Xcode Command Line Tools first: xcode-select --install" >&2
  exit 1
fi

echo "==> Cleaning previous build"
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "==> Copying app files"
cp Notebook.html "$RESOURCES_DIR/"
if [ -d "icons" ]; then
  cp -r icons "$RESOURCES_DIR/"
fi

echo "==> Compiling native wrapper (main.swift)"
swiftc main.swift -O -o "$MACOS_DIR/$APP_NAME" -framework Cocoa -framework WebKit

echo "==> Writing Info.plist"
cat > "$CONTENTS_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Building icon"
if [ -f "icons/icon-512.png" ]; then
  ICONSET="$BUILD_DIR/AppIcon.iconset"
  mkdir -p "$ICONSET"
  sips -z 16 16    icons/icon-512.png --out "$ICONSET/icon_16x16.png"       >/dev/null
  sips -z 32 32    icons/icon-512.png --out "$ICONSET/icon_16x16@2x.png"    >/dev/null
  sips -z 32 32    icons/icon-512.png --out "$ICONSET/icon_32x32.png"       >/dev/null
  sips -z 64 64    icons/icon-512.png --out "$ICONSET/icon_32x32@2x.png"    >/dev/null
  sips -z 128 128  icons/icon-512.png --out "$ICONSET/icon_128x128.png"     >/dev/null
  sips -z 256 256  icons/icon-512.png --out "$ICONSET/icon_128x128@2x.png"  >/dev/null
  sips -z 256 256  icons/icon-512.png --out "$ICONSET/icon_256x256.png"     >/dev/null
  sips -z 512 512  icons/icon-512.png --out "$ICONSET/icon_256x256@2x.png"  >/dev/null
  sips -z 512 512  icons/icon-512.png --out "$ICONSET/icon_512x512.png"     >/dev/null
  cp icons/icon-512.png "$ICONSET/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
  rm -rf "$ICONSET"
else
  echo "    (no icons/icon-512.png found — app will use the generic icon)"
fi

echo "==> Clearing quarantine attributes"
xattr -cr "$APP_DIR" || true

echo "==> Zipping for distribution"
(cd "$BUILD_DIR" && zip -r -q "$APP_NAME-mac.zip" "$APP_NAME.app")

echo ""
echo "Done. Built:"
echo "  $APP_DIR"
echo "  $BUILD_DIR/$APP_NAME-mac.zip"
echo ""
echo "NOTE: this app is unsigned. On first launch, macOS Gatekeeper will warn"
echo "that it's from an unidentified developer. Right-click -> Open (or"
echo "System Settings -> Privacy & Security -> Open Anyway) to get past that"
echo "the first time."
