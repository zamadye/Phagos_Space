#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$ROOT/.local/godot/Godot_v4.6.2-stable_linux.x86_64}"
PROJECT="$ROOT/project.godot"
BACKUP="$(mktemp)"
cp "$PROJECT" "$BACKUP"
restore_project() {
  cp "$BACKUP" "$PROJECT"
  rm -f "$BACKUP"
}
trap restore_project EXIT

python3 - "$PROJECT" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = 'run/main_scene="res://scenes/Main.tscn"'
new = 'run/main_scene="res://scenes/WallStudy.tscn"'
if old not in text:
    raise SystemExit("Main scene setting was not found")
path.write_text(text.replace(old, new, 1))
PY

"$GODOT_BIN" --headless --path "$ROOT" --export-debug Web "$ROOT/wall-study.html"
printf 'Wall study export ready: %s\n' "$ROOT/wall-study.html"
