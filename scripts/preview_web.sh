#!/usr/bin/env bash
# Export (when needed) and serve the Godot Web build for browser/WebView preview.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/web"
PORT="${WEB_PREVIEW_PORT:-8008}"
# Bind broadly for sandbox proxy previews while retaining a useful local URL.
HOST="${WEB_PREVIEW_HOST:-0.0.0.0}"
DISPLAY_HOST="${WEB_PREVIEW_URL_HOST:-127.0.0.1}"

if [[ ! -s "$BUILD_DIR/index.html" ]]; then
  "$ROOT_DIR/scripts/export_web.sh" --release
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to serve the Web export locally." >&2
  exit 127
fi

echo "Serving the Godot Web export at http://$DISPLAY_HOST:$PORT"
echo "Press Ctrl+C to stop the local preview server."
exec python3 -m http.server "$PORT" --bind "$HOST" --directory "$BUILD_DIR"
