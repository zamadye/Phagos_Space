#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$ROOT/.local/blender_python" "$ROOT/.local/blender_stubs"
python3 -m pip install --target "$ROOT/.local/blender_python" bpy==5.0.1
for spec in libXrender.so.1 libXfixes.so.3 libXi.so.6 libSM.so.6 libICE.so.6; do
  gcc -shared -fPIC "$ROOT/tools/blender/blender_runtime_stubs.c" \
    -Wl,-soname,"$spec" -o "$ROOT/.local/blender_stubs/$spec"
done
gcc -shared -fPIC "$ROOT/tools/blender/blender_runtime_stubs.c" \
  -Wl,-soname,libxkbcommon.so.0 \
  -Wl,--version-script="$ROOT/tools/blender/blender_runtime_xkb.map" \
  -o "$ROOT/.local/blender_stubs/libxkbcommon.so.0"
gcc -shared -fPIC "$ROOT/tools/blender/blender_runtime_stubs.c" \
  -Wl,-soname,libGL.so.1 -o "$ROOT/.local/blender_stubs/libGL.so.1"
"$ROOT/tools/blender/run_bpy.sh" - <<'PY'
import bpy
print(f"BLENDER_READY {bpy.app.version_string} background={bpy.app.background}")
PY
