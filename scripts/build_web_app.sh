#!/usr/bin/env bash
# Produce a static HTML/JS application bundle with the Godot engine payload.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$ROOT_DIR/web"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to build the HTML/JS web application." >&2
  exit 127
fi

if [[ ! -s "$WEB_DIR/public/engine/index.html" ]]; then
  "$ROOT_DIR/scripts/export_web.sh" --release
fi

if [[ ! -d "$WEB_DIR/node_modules" ]]; then
  npm --prefix "$WEB_DIR" install
fi

npm --prefix "$WEB_DIR" run build
printf 'Web application bundle ready: %s\n' "$WEB_DIR/dist/index.html"
