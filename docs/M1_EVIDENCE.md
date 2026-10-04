# M1 validation evidence

Tanggal validasi: **2026-10-05**  
Branch: `arena/01a107da-phagos-space`

M1 masih **IN PROGRESS**. Evidence di bawah membuktikan runtime, export, dan root-server contract; visual screenshot comparison dan an interactive desktop/browser capture masih menjadi pekerjaan berikutnya.

## Reproducible commands

Toolchain lokal disiapkan dari arsip yang sudah ada di repository:

```bash
./scripts/prepare_toolchain.sh
```

Godot editor/headless parse and import validation:

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --editor --quit
```

Result: exit code `0`, no GDScript parse error.

## Gameplay smoke run

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --quit-after 7000
```

Observed deterministic runtime log:

```text
M1 arena ready: path_length=274.4m; hazards=6
M1 hazard collision: index=1 hit_count=1
M1 session complete: distance=271.4m; hits=1
```

This exercises scene boot, procedural 3D construction, Curve3D forward movement, hazard proximity/collision response, and automatic finish without login or external services.

## Web export evidence

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --export-debug Web index.html
```

Canonical root files produced:

| File | Size at validation |
|---|---:|
| `index.html` | 5,298 bytes |
| `index.js` | 279,925 bytes |
| `index.wasm` | 35,749,181 bytes |
| `index.pck` | 1,488,876 bytes |

Additional Web runtime files (`index.png`, audio worklets) are kept because the generated HTML references them.

Root server check:

```bash
python3 -m http.server 8000 --bind 0.0.0.0
curl -fsSI http://127.0.0.1:8000/index.html
curl -fsSI http://127.0.0.1:8000/index.wasm
```

Observed: both responses were `200 OK`; `.wasm` was served as `application/wasm`.

## Remaining evidence before M1 can be marked DONE

- Capture a 1024×1024 browser/desktop gameplay screenshot and compare it against `Gameplay-Arena.jpg`.
- Capture a visible start → active run → hazard → finish → retry smoke sequence.
- Run browser WebGL smoke test. The repository includes `tools/browser/smoke.mjs`; the current sandbox could not launch its Chromium binary because the OS image lacks `libnspr4.so`, `libnss3.so`, and `libnssutil3.so`. This is an environment limitation, not a game runtime error.
