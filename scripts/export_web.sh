#!/usr/bin/env bash
# Export the Godot engine payload that is embedded by the HTML/JS application.
# The resulting engine page is intentionally a child of web/public/engine, not
# the top-level browser application.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_DIR="$ROOT_DIR/web/public/engine"
OUTPUT_PATH="$ENGINE_DIR/index.html"
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

rm -rf "$ENGINE_DIR"
mkdir -p "$ENGINE_DIR"

echo "Exporting Godot engine payload to $OUTPUT_PATH"
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

cp "$ROOT_DIR/web/engine_bridge.js" "$ENGINE_DIR/ui_bridge.js"
python3 "$ROOT_DIR/tools/inject_web_bridge.py" "$OUTPUT_PATH"
echo "Godot engine payload ready for the web app: $OUTPUT_PATH"
