#!/usr/bin/env bash
# Export the native Godot project to a browser/WebView-compatible Web build.
# No game code is implemented in HTML here: Godot generates the shell, JS, WASM,
# and pack files from project.godot, scenes, assets, and GDScript.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/web"
OUTPUT_PATH="$BUILD_DIR/index.html"
EXPORT_MODE="--export-release"

case "${1:-}" in
  ""|--release)
    ;;
  --debug)
    EXPORT_MODE="--export-debug"
    ;;
  *)
    echo "Usage: $0 [--release|--debug]" >&2
    exit 64
    ;;
esac

if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT_COMMAND=("$GODOT_BIN")
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_COMMAND=(godot4)
elif command -v godot >/dev/null 2>&1; then
  GODOT_COMMAND=(godot)
elif command -v flatpak >/dev/null 2>&1 && flatpak info org.godotengine.Godot >/dev/null 2>&1; then
  GODOT_COMMAND=(flatpak run org.godotengine.Godot)
else
  cat >&2 <<'MESSAGE'
Godot 4.3 or newer was not found on PATH.

Install the native Godot editor, then retry. On Flatpak-enabled Linux systems:
  flatpak install flathub org.godotengine.Godot

Alternatively set GODOT_BIN to an explicit Godot executable path.
MESSAGE
  exit 127
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Exporting native Godot project to $OUTPUT_PATH"
if ! "${GODOT_COMMAND[@]}" --headless --path "$ROOT_DIR" "$EXPORT_MODE" Web "$OUTPUT_PATH"; then
  cat >&2 <<'MESSAGE'

The Godot Web export did not complete. If Godot reports missing export templates,
open the Godot editor and install the matching 4.3 export templates from
Editor > Manage Export Templates, then run this script again.
MESSAGE
  exit 1
fi

if [[ ! -s "$OUTPUT_PATH" ]]; then
  echo "Godot completed without creating $OUTPUT_PATH" >&2
  exit 1
fi

echo "Web export ready: $OUTPUT_PATH"
