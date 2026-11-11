#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# External volume can trip SwiftPM's sandbox; env notes document this escape hatch.
export SWIFTPM_DISABLE_SANDBOX=1
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/swiftpm-module-cache"
export XDG_CACHE_HOME="${TMPDIR:-/tmp}/swiftpm-cache"

swift build -c release --arch arm64

APP=build/Twenty20.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Twenty20 "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
cp PkgInfo "$APP/Contents/" 2>/dev/null || printf 'APPL????' > "$APP/Contents/PkgInfo"

# App icon: composite the transparent artwork onto the navy gradient.
ICONSET=build/Twenty20.iconset
rm -rf "$ICONSET" build/Twenty20.icns
swift scripts/make_iconset.swift Assets/icon-alpha.png "$ICONSET" >/dev/null
iconutil -c icns "$ICONSET" -o build/Twenty20.icns
cp build/Twenty20.icns "$APP/Contents/Resources/"

codesign --force --sign - "$APP" >/dev/null
echo "Built $APP"
echo "Run: open $APP   (dev loop without bundle: swift run Twenty20)"
