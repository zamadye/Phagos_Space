# M1 validation evidence

Tanggal validasi: **2026-10-05**  
Branch: `arena/01a107da-phagos-space`

M1 masih **IN PROGRESS**. Evidence di bawah membuktikan runtime, export, root-server contract, browser WebGL boot, debug reference overlay, dan satu sesi browser start → active → hazard → finish → retry. Overlay sudah tersedia; final art/framing calibration terhadap `Gameplay-Arena.jpg` masih menjadi pekerjaan berikutnya.

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
| `index.pck` | 2,593,232 bytes |

Additional Web runtime files (`index.png`, audio worklets) are kept because the generated HTML references them.

Release template validation was also run to a temporary directory (without replacing the canonical debug files):

```bash
.local/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path . --export-release Web /tmp/phagos-web-release/index.html
```

Result: release `index.html`, `index.js`, `index.wasm`, and `index.pck` were all generated successfully.

Root server check:

```bash
python3 -m http.server 8000 --bind 0.0.0.0
curl -fsSI http://127.0.0.1:8000/index.html
curl -fsSI http://127.0.0.1:8000/index.wasm
```

Observed: both responses were `200 OK`; `.wasm` was served as `application/wasm`.

## Browser WebGL smoke evidence

The browser smoke test uses Puppeteer Core and `@sparticuz/chromium`. The important workaround is implemented in `tools/browser/smoke.mjs`: it sets the package's AL2023 compatibility path before dynamically importing Chromium. The package then extracts its bundled `al2023.tar.br` libraries and sets `LD_LIBRARY_PATH`, so the test does not depend on system-installed `libnspr4.so`, `libnss3.so`, or `libnssutil3.so`.

Reproducible command after the root server is running:

```bash
cd tools/browser
npm ci --ignore-scripts
npm run smoke
```

Observed result:

```json
{
  "title": "Phagos Space (DEBUG)",
  "canvas": true,
  "canvasBox": { "width": 1024, "height": 1024 },
  "errors": []
}
```

Screenshot evidence: `evidence/m1-web-smoke.png`.

## Full M1 debug QA sequence

The longer browser QA script is `tools/browser/m1_qa.mjs` and is exposed as:

```bash
cd tools/browser
npm run qa:m1
```

It captures and validates the visible sequence:

- `evidence/m1-web-boot.png` — boot/start state.
- `evidence/m1-reference-overlay.png` — F2 debug overlay with `Gameplay-Arena.jpg` at 32% opacity.
- `evidence/m1-web-active.png` — active movement state.
- `evidence/m1-web-finish.png` — `SESSION COMPLETE`, distance, and retry prompt.
- `evidence/m1-web-retry.png` — `R` resets the run to `003%`, `ACTIVE`, and `HITS 00`.

The current software-rendered Chromium needs an extended wait because it can run below 60 FPS; the QA script allows enough time for the full 274.4m run.

## Remaining evidence before M1 can be marked DONE

- Use the captured overlay to calibrate vanishing point, foreground rail width, path width, and avatar position against `Gameplay-Arena.jpg`.
- Decide whether the procedural player is visually sufficient for M1 or should be replaced with a validated GLB in M2.
