#!/usr/bin/env bash
# Serve the release exactly as a browser will receive it.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$PROJECT_ROOT/build/web"
PORT="${PORT:-8080}"
URL="http://localhost:${PORT}"

if [[ ! -s "$WEB_DIR/index.html" || ! -s "$WEB_DIR/phagos.js" || ! -s "$WEB_DIR/phagos.wasm" || ! -s "$WEB_DIR/phagos.pck" ]]; then
    echo "Web build is missing; exporting a release first..."
    "$PROJECT_ROOT/scripts/export_web.sh"
fi

echo "Phagos Web Preview"
echo "  $URL"
echo "Press Ctrl+C to stop the server."

# Browser opening is best-effort so headless CI and remote shells stay usable.
if command -v xdg-open >/dev/null 2>&1; then
    (sleep 0.6 && xdg-open "$URL" >/dev/null 2>&1) &
elif command -v open >/dev/null 2>&1; then
    (sleep 0.6 && open "$URL" >/dev/null 2>&1) &
fi

exec python3 -m http.server "$PORT" --directory "$WEB_DIR"
