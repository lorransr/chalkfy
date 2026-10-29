#!/bin/sh
# Usage: ./bundle.sh [swift build flags], e.g. --arch arm64 --arch x86_64 (needs Xcode).
# SIGN_ID: SHA-1 of a code signing identity in the keychain search list, else ad hoc.
# A self-signed identity keeps the Accessibility grant across rebuilds.
# VERSION and BUILD set CFBundleShortVersionString and CFBundleVersion.
set -e
cd "$(dirname "$0")"
swift build -c release "$@"
APP=build/Chalkfy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp brand/AppIcon.icns brand/MenuBarTemplate.pdf "$APP/Contents/Resources/"
cp "$(swift build -c release "$@" --show-bin-path)/Chalkfy" "$APP/Contents/MacOS/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.lorransr.chalkfy</string>
  <key>CFBundleName</key><string>Chalkfy</string>
  <key>CFBundleExecutable</key><string>Chalkfy</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION:-0.0.0}</string>
  <key>CFBundleVersion</key><string>${BUILD:-0}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign -f -s "${SIGN_ID:--}" "$APP"
