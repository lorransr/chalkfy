#!/bin/sh
# swift test with Command Line Tools only. SwiftPM does not put CLT's Testing.framework on the
# search path of its generated test runner, so per-target flags in Package.swift are not enough:
# the tests would build and none would run. With Xcode, plain `swift test` works.
set -e
cd "$(dirname "$0")"
DEV=/Library/Developer/CommandLineTools/Library/Developer
swift test -Xswiftc -F$DEV/Frameworks \
  -Xlinker -rpath -Xlinker $DEV/Frameworks -Xlinker -rpath -Xlinker $DEV/usr/lib "$@"
