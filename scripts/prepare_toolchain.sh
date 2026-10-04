#!/usr/bin/env bash
set -euo pipefail

# Reproducible, offline-first staging for the assets already present in this repo.
# Nothing under .local/ is part of the game source or meant to be committed.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT_ZIP="Godot_v4.6.2-stable_linux.x86_64.zip"
GODOT_BIN=".local/godot/Godot_v4.6.2-stable_linux.x86_64"
DEBUG_ZIP="web_nothreads_debug.zip"
RELEASE_ZIP="web_nothreads_release.zip"
CHROMIUM_VERSION="153.0.0"
CHROMIUM_TGZ=".local/npm-pack/sparticuz-chromium-${CHROMIUM_VERSION}.tgz"

mkdir -p .local/godot .local/web_templates/debug .local/web_templates/release .local/npm-pack

if [[ ! -x "$GODOT_BIN" ]]; then
  [[ -f "$GODOT_ZIP" ]] || { echo "Missing $GODOT_ZIP" >&2; exit 1; }
  unzip -p "$GODOT_ZIP" > "$GODOT_BIN"
  chmod +x "$GODOT_BIN"
fi

if [[ ! -f .local/web_templates/debug/godot.wasm ]]; then
  [[ -f "$DEBUG_ZIP" ]] || { echo "Missing $DEBUG_ZIP" >&2; exit 1; }
  unzip -oq "$DEBUG_ZIP" -d .local/web_templates/debug
fi

if [[ ! -f .local/web_templates/release/godot.wasm ]]; then
  [[ -f "$RELEASE_ZIP" ]] || { echo "Missing $RELEASE_ZIP" >&2; exit 1; }
  unzip -oq "$RELEASE_ZIP" -d .local/web_templates/release
fi

if [[ ! -f "$CHROMIUM_TGZ" ]]; then
  command -v npm >/dev/null || { echo "npm is required to pack @sparticuz/chromium" >&2; exit 1; }
  npm pack "@sparticuz/chromium@${CHROMIUM_VERSION}" --pack-destination .local/npm-pack
fi

printf 'Godot: '
"$GODOT_BIN" --version
printf 'Web debug template: '
stat -c '%s bytes' .local/web_templates/debug/godot.wasm
printf 'Web release template: '
stat -c '%s bytes' .local/web_templates/release/godot.wasm
printf 'Chromium pack: '
stat -c '%s bytes' "$CHROMIUM_TGZ"
printf 'Chromium SHA-256: '
sha256sum "$CHROMIUM_TGZ" | cut -d ' ' -f 1
