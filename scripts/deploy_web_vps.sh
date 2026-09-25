#!/usr/bin/env bash
# Export then deploy the browser release atomically enough for a static nginx site.
# Required: VPS_HOST. Optional: VPS_USER, VPS_PORT, VPS_PATH, VPS_SSH_KEY,
# VPS_NGINX_RELOAD_COMMAND, VPS_TARGET.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$PROJECT_ROOT/build/web"
VPS_PATH="${VPS_PATH:-/var/www/phagos-arena}"
VPS_PORT="${VPS_PORT:-22}"
VPS_USER="${VPS_USER:-deploy}"

if [[ -n "${VPS_TARGET:-}" ]]; then
    REMOTE="$VPS_TARGET"
elif [[ -n "${VPS_HOST:-}" ]]; then
    REMOTE="${VPS_USER}@${VPS_HOST}"
else
    echo "error: set VPS_HOST (and optionally VPS_USER) or provide VPS_TARGET=user@host." >&2
    exit 2
fi

SSH_OPTIONS=(-p "$VPS_PORT" -o BatchMode=yes)
if [[ -n "${VPS_SSH_KEY:-}" ]]; then
    SSH_OPTIONS+=(-i "$VPS_SSH_KEY")
fi

"$PROJECT_ROOT/scripts/export_web.sh"

# Ensure failed transfers never leave a partially populated document root.
ssh "${SSH_OPTIONS[@]}" "$REMOTE" "mkdir -p '$VPS_PATH'"
rsync -az --delete --checksum \
    -e "ssh ${SSH_OPTIONS[*]}" \
    "$WEB_DIR/" "$REMOTE:$VPS_PATH/"

RELOAD_COMMAND="${VPS_NGINX_RELOAD_COMMAND:-sudo nginx -t && sudo systemctl reload nginx}"
ssh "${SSH_OPTIONS[@]}" "$REMOTE" "$RELOAD_COMMAND"

echo "Deployed Phagos Web preview to $REMOTE:$VPS_PATH"
