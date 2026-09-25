# Phagos browser validation

Generated: 2026-09-25T23:22:36.837Z

Target URL: http://127.0.0.1:8080

Browser surface: **headed via Xvfb**. rAF gate: **≥ 55 FPS** (desktop browser target remains 60 FPS).

| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS gate | Console errors |
|---|---:|---:|---:|---:|---:|---:|
| Chrome | PASS | PASS | FAIL | 6.0 | FAIL | FAIL |
| Firefox | PASS | PASS | FAIL | 5.3 | FAIL | FAIL |
| Edge | PASS | PASS | FAIL | 4.9 | FAIL | FAIL |

## WASM delivery
- **Chrome:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Firefox:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Edge:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm

## Diagnostics
- **Chrome:** `Failed to load resource: the server responded with a status of 404 (File not found)`; `HTTP 404 http://127.0.0.1:8080/index.icon.png`
- **Firefox:** `HTTP 404 http://127.0.0.1:8080/index.apple-touch-icon.png`; `HTTP 404 http://127.0.0.1:8080/index.icon.png`
- **Edge:** `Failed to load resource: the server responded with a status of 404 (File not found)`; `HTTP 404 http://127.0.0.1:8080/index.icon.png`

## Result

**FAIL** — Chrome, Firefox, and Edge must all pass before the Web preview is promoted.
