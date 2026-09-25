# Phagos browser validation

Generated: 2026-09-25T23:27:53.064Z

Target URL: http://127.0.0.1:8080

Browser surface: **headed via Xvfb**. rAF gate: **≥ 55 FPS** (desktop browser target remains 60 FPS).

| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS gate | Console errors |
|---|---:|---:|---:|---:|---:|---:|
| Chrome | PASS | PASS | PASS | 5.0 | FAIL | PASS |
| Firefox | PASS | PASS | PASS | 5.2 | FAIL | PASS |
| Edge | PASS | PASS | PASS | 4.9 | FAIL | PASS |

## WASM delivery
- **Chrome:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Firefox:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Edge:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm

## Diagnostics
- **Chrome:** no console or WebGL errors observed.
- **Firefox:** no console or WebGL errors observed.
- **Edge:** no console or WebGL errors observed.

## Result

**FAIL** — Chrome, Firefox, and Edge must all pass before the Web preview is promoted.
