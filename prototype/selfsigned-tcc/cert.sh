#!/bin/sh
# PROTOTYPE, throwaway. Makes a self-signed code signing identity in its own keychain,
# the same way CI would import the .p12 secret. Does not touch the login keychain.
set -e
cd "$(dirname "$0")"
mkdir -p build
KC="$PWD/build/proto.keychain-db"
PW=prototype
# LibreSSL on purpose: OpenSSL 3 writes a .p12 that `security import` rejects.
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout build/key.pem -out build/cert.pem -subj "/CN=Chalkfy Prototype" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"
/usr/bin/openssl pkcs12 -export -inkey build/key.pem -in build/cert.pem -out build/cert.p12 -passout pass:$PW
security delete-keychain "$KC" 2>/dev/null || true
security create-keychain -p $PW "$KC"
security unlock-keychain -p $PW "$KC"
security import build/cert.p12 -k "$KC" -P $PW -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k $PW "$KC" >/dev/null
security find-identity -p codesigning "$KC"
