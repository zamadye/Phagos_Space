# Phagos browser validation

Generated: 2026-09-26T06:54:45.419Z

Target URL: http://127.0.0.1:8080

Browser surface: **headed via Xvfb**. Desktop rAF gate: **≥ 55 FPS** (desktop target remains 60 FPS). A software smoke floor of **≥ 1 FPS** is active; it does not replace the desktop gate.

| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS policy | Console errors |
|---|---:|---:|---:|---:|---:|---:|
| Chrome | FAIL | FAIL | FAIL | 0.0 | FAIL | FAIL |
| Firefox | PASS | PASS | PASS | 4.8 | SMOKE | PASS |
| Edge | PASS | PASS | PASS | 4.5 | SMOKE | PASS |

## WASM delivery
- **Chrome:** WASM response not observed
- **Firefox:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Edge:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm

## Frame timing
- **Chrome:** 0.0 FPS · renderer unavailable · FAIL (requires ≥ 55 FPS or ≥ 1 FPS on the configured software smoke surface)
- **Firefox:** 4.8 FPS · Mesa · llvmpipe, or similar · software smoke PASS (≥ 1 FPS); desktop ≥ 55 FPS remains unverified
- **Edge:** 4.5 FPS · Google Inc. (Mesa) · ANGLE (Mesa, llvmpipe (LLVM 20.1.2 256 bits), OpenGL 4.5) · software smoke PASS (≥ 1 FPS); desktop ≥ 55 FPS remains unverified

## Diagnostics
- **Chrome:** `page.waitForSelector: Timeout 15000ms exceeded.
Call log:
  - waiting for locator('#canvas') to be visible
    - locator resolved to visible <canvas id="canvas" width="1920" height="1080">Your browser does not support the canvas element.</canvas>

    at inspectTarget (/home/runner/work/Phagos_Space/Phagos_Space/tools/browser_qa.mjs:86:20)
    at async file:///home/runner/work/Phagos_Space/Phagos_Space/tools/browser_qa.mjs:158:18`; `TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
Call log:
  - waiting for locator('#canvas') to be visible
    - locator resolved to visible <canvas id="canvas" width="1920" height="1080">Your browser does not support the canvas element.</canvas>
`
- **Firefox:** no console or WebGL errors observed.
- **Edge:** no console or WebGL errors observed.

## Result

**FAIL** — Chrome, Firefox, and Edge must all pass the configured Web delivery, WebGL, console, and frame-timing gates before promotion.
