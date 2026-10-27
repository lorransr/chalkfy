#!/bin/sh
# PROTOTYPE, throwaway. Builds an ad hoc signed .app so TCC prompts name the app, not Terminal.
set -e
cd "$(dirname "$0")"
APP=build/ChalkfyRing.app
mkdir -p "$APP/Contents/MacOS"
swiftc -O main.swift -o "$APP/Contents/MacOS/ChalkfyRing"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.lorransr.chalkfy.prototype.ring</string>
  <key>CFBundleName</key><string>ChalkfyRing</string>
  <key>CFBundleExecutable</key><string>ChalkfyRing</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF
codesign -s - -f "$APP"
[ "$1" = "--build-only" ] && exit 0
: > ring.log
open -n --stdout "$PWD/ring.log" --stderr "$PWD/ring.log" "$APP"
tail -f ring.log
