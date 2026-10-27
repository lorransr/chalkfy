#!/bin/sh
# Builds and signs build/Chalkfy.app. Signs ad hoc unless SIGN_ID is the SHA-1 of a code signing
# identity in the keychain search list; a self-signed one keeps the Accessibility grant across rebuilds.
set -e
cd "$(dirname "$0")"
swift build -c release
APP=build/Chalkfy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/Chalkfy" "$APP/Contents/MacOS/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.lorransr.chalkfy</string>
  <key>CFBundleName</key><string>Chalkfy</string>
  <key>CFBundleExecutable</key><string>Chalkfy</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign -f -s "${SIGN_ID:--}" "$APP"
