#!/usr/bin/env bash
# Start the actual HTML/JS application shell. It embeds the Godot engine at
# /engine/ and is the URL a browser/WebView should open.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$ROOT_DIR/web"
PORT="${WEB_PREVIEW_PORT:-5173}"

if [[ ! -s "$WEB_DIR/public/engine/index.html" ]]; then
  "$ROOT_DIR/scripts/export_web.sh" --release
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to start the HTML/JS web application." >&2
  exit 127
fi

if [[ ! -d "$WEB_DIR/node_modules" ]]; then
  echo "Installing web application dependencies..."
  npm --prefix "$WEB_DIR" install
fi

echo "Serving the PHAGOS web application at http://127.0.0.1:$PORT"
echo "The Godot engine is embedded at /engine/ behind this application shell."
exec npm --prefix "$WEB_DIR" run dev -- --host 0.0.0.0 --port "$PORT"
