#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PYTHONPATH="$ROOT/.local/blender_python${PYTHONPATH:+:$PYTHONPATH}"
export LD_LIBRARY_PATH="$ROOT/.local/blender_stubs:$ROOT/.local/blender_python/bpy/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec python3 "$@"
