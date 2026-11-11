#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Builds build/Twenty20.app then wraps it in a styled DMG.
./scripts/package_app.sh

ROOT=build/dmg-root
BG=build/Twenty20-dmg-bg.png
DMG=build/Twenty20.dmg

rm -rf "$ROOT" "$BG" "$DMG"
mkdir -p "$ROOT"
cp -R build/Twenty20.app "$ROOT/"

swift scripts/make_dmg_background.swift "$BG" >/dev/null

create-dmg \
  --volname Twenty20 \
  --volicon build/Twenty20.icns \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --background "$BG" \
  --icon "Twenty20.app" 200 180 \
  --app-drop-link 460 180 \
  --hide-extension "Twenty20.app" \
  --no-internet-enable \
  "$DMG" "$ROOT"

echo "Built $DMG"
