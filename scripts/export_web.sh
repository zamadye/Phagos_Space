#!/usr/bin/env bash
# Build a deterministic, single-threaded Godot Web release.
# Godot emits index.* for an index.html export; the post-step keeps index.html as the
# web entry point while normalizing runtime payloads to phagos.* for deployment.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build/web"
GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
    echo "error: Godot executable '$GODOT_BIN' was not found. Set GODOT_BIN=/path/to/godot." >&2
    exit 127
fi

if [[ ! -f "$PROJECT_ROOT/export_presets.cfg" ]]; then
    echo "error: export_presets.cfg is missing." >&2
    exit 1
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Keep this invocation intentionally explicit; CI and local builds use the same preset.
(
    cd "$PROJECT_ROOT"
    "$GODOT_BIN" --headless --export-release Web build/web/index.html
)

# Godot's generated payload base follows index.html. Preserve index.html for static hosts,
# but give the cached executable/wasm/pck payload a stable product name.
for extension in js wasm pck; do
    source_file="$OUTPUT_DIR/index.$extension"
    target_file="$OUTPUT_DIR/phagos.$extension"
    if [[ ! -s "$source_file" ]]; then
        echo "error: export did not produce required payload: $source_file" >&2
        exit 1
    fi
    mv "$source_file" "$target_file"
done

# Godot may generate optional loader sidecars. Keep names consistent when present.
while IFS= read -r -d '' sidecar; do
    renamed="${sidecar##*/}"
    renamed="${renamed/index./phagos.}"
    mv "$sidecar" "$OUTPUT_DIR/$renamed"
done < <(find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'index.*' ! -name 'index.html' -print0)

python3 - "$OUTPUT_DIR/index.html" <<'PY'
from pathlib import Path
import re
import sys

html_path = Path(sys.argv[1])
html = html_path.read_text(encoding="utf-8")
for extension in ("js", "wasm", "pck", "audio.worklet.js"):
    html = html.replace(f"index.{extension}", f"phagos.{extension}")
# Godot's config can be minified or pretty-printed depending on engine minor version.
html = re.sub(
    r'(["\']executable["\']\s*:\s*["\'])index(["\'])',
    r'\1phagos\2',
    html,
)
html_path.write_text(html, encoding="utf-8")
PY

touch "$OUTPUT_DIR/.nojekyll"

# Static hosts need canonical files. Brotli sidecars are emitted for nginx/CDNs that support
# content negotiation; GitHub Pages transparently falls back to the canonical files.
if command -v brotli >/dev/null 2>&1; then
    brotli --force --keep --quality=11 "$OUTPUT_DIR/index.html" "$OUTPUT_DIR/phagos.js" "$OUTPUT_DIR/phagos.wasm" "$OUTPUT_DIR/phagos.pck"
else
    echo "warning: brotli is not installed; canonical Web payloads were built without .br sidecars." >&2
fi

for required in index.html phagos.js phagos.wasm phagos.pck; do
    if [[ ! -s "$OUTPUT_DIR/$required" ]]; then
        echo "error: expected build/web/$required after export." >&2
        exit 1
    fi
done

echo "Web release ready: $OUTPUT_DIR"
printf '  %-18s %10s bytes\n' index.html "$(wc -c < "$OUTPUT_DIR/index.html")"
printf '  %-18s %10s bytes\n' phagos.js "$(wc -c < "$OUTPUT_DIR/phagos.js")"
printf '  %-18s %10s bytes\n' phagos.wasm "$(wc -c < "$OUTPUT_DIR/phagos.wasm")"
printf '  %-18s %10s bytes\n' phagos.pck "$(wc -c < "$OUTPUT_DIR/phagos.pck")"
