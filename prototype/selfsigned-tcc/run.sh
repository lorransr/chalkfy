#!/bin/sh
# PROTOTYPE, throwaway. Usage: ./run.sh <build number> [--quarantine]
# Each build number compiles to a different binary (new cdhash), signed with the same certificate.
# --quarantine ships it the way a user gets it: zip, download flag, unzip into build/download.
set -e
cd "$(dirname "$0")"
N=$1
APP=build/ChalkfyTCC.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O main.swift -o "$APP/Contents/MacOS/ChalkfyTCC"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.lorransr.chalkfy.prototype.tcc</string>
  <key>CFBundleName</key><string>ChalkfyTCC</string>
  <key>CFBundleExecutable</key><string>ChalkfyTCC</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>$N</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF
KC="$PWD/build/proto.keychain-db"
security unlock-keychain -p prototype "$KC"
# codesign finds the identity only through the search list, and only by hash: a self-signed
# certificate is not trusted, so codesign rejects its name. No trust setting is needed.
ID=$(security find-identity -p codesigning "$KC" | awk '/Chalkfy Prototype/ {print $2; exit}')
ORIG=$(security list-keychains -d user | tr -d '"')
security list-keychains -d user -s $ORIG "$KC"
codesign -f -s "$ID" "$APP" || { security list-keychains -d user -s $ORIG; exit 1; }
security list-keychains -d user -s $ORIG
codesign -dvvv "$APP" 2>&1 | grep -E 'CDHash=|Authority='
codesign -d -r- "$APP" 2>&1 | grep designated
if [ "$2" = "--quarantine" ]; then
  rm -rf build/download build/ChalkfyTCC.zip
  ditto -c -k --keepParent "$APP" build/ChalkfyTCC.zip
  mkdir build/download
  ditto -x -k build/ChalkfyTCC.zip build/download
  xattr -w com.apple.quarantine "0081;$(printf %x "$(date +%s)");Safari;" build/download/ChalkfyTCC.app
  APP=build/download/ChalkfyTCC.app
fi
: > tcc.log
open -n --stdout "$PWD/tcc.log" --stderr "$PWD/tcc.log" "$APP"
tail -f tcc.log
