#!/bin/sh
# Makes the release signing certificate, once. Usage: ./cert.sh <dir outside the repo>
# The Accessibility grant is bound to this certificate, so a new one costs every Presenter the
# grant: back up the .p12 and its password. Then set the repo secrets:
#   base64 -i <dir>/chalkfy.p12 | gh secret set SIGNING_P12
#   gh secret set SIGNING_P12_PASSWORD < <dir>/chalkfy.p12.password
set -e
umask 077
OUT=${1:?usage: $0 <dir>}
[ ! -e "$OUT/chalkfy.p12" ] || { echo "$OUT/chalkfy.p12 exists; never replace it" >&2; exit 1; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
/usr/bin/openssl rand -base64 24 | tr -d '\n' > "$OUT/chalkfy.p12.password"
# LibreSSL on purpose: OpenSSL 3 writes a .p12 that `security import` rejects.
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -subj "/CN=Chalkfy" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"
/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -out "$OUT/chalkfy.p12" -passout "file:$OUT/chalkfy.p12.password"
