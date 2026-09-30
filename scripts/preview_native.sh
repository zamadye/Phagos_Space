#!/usr/bin/env bash
# Launch the playable PHAGOS Godot project with a locally installed native runtime.
# Browser/WebView delivery is generated separately by scripts/export_web.sh.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT_COMMAND="$GODOT_BIN"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_COMMAND="godot4"
elif command -v godot >/dev/null 2>&1; then
  GODOT_COMMAND="godot"
elif command -v flatpak >/dev/null 2>&1 && flatpak info org.godotengine.Godot >/dev/null 2>&1; then
  cd "$ROOT_DIR"
  exec flatpak run org.godotengine.Godot --path "$ROOT_DIR" "$@"
else
  cat >&2 <<'MESSAGE'
Godot 4.3 or newer was not found on PATH.

Install the native Godot editor, then retry. On Flatpak-enabled Linux systems:
  flatpak install flathub org.godotengine.Godot
  flatpak run org.godotengine.Godot --path .

Or set GODOT_BIN to an explicit Godot executable path.
MESSAGE
  exit 127
fi

cd "$ROOT_DIR"
exec "$GODOT_COMMAND" --path "$ROOT_DIR" "$@"
