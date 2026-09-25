# Phagos browser validation

Generated: 2026-09-25T22:49:17.528Z

Target URL: http://127.0.0.1:8080

Headless rAF gate: **≥ 55 FPS** (desktop browser target remains 60 FPS).

| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS gate | Console errors |
|---|---:|---:|---:|---:|---:|---:|
| Chrome | PASS | PASS | FAIL | 0.9 | FAIL | FAIL |
| Firefox | FAIL | FAIL | FAIL | 0.0 | FAIL | FAIL |
| Edge | PASS | PASS | FAIL | 1.0 | FAIL | FAIL |

## WASM delivery
- **Chrome:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Firefox:** WASM response not observed
- **Edge:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm

## Diagnostics
- **Chrome:** `Failed to load resource: the server responded with a status of 404 (File not found)`
- **Firefox:** `page.waitForFunction: Timeout 60000ms exceeded.
    at inspectTarget (/home/runner/work/Phagos_Space/Phagos_Space/tools/browser_qa.mjs:68:20)
    at async file:///home/runner/work/Phagos_Space/Phagos_Space/tools/browser_qa.mjs:110:18`; `[Phagos Web] bootstrap failed: Missing browser capability: WebGL2 - Check web browser configuration and hardware support`; `TimeoutError: page.waitForFunction: Timeout 60000ms exceeded.`
- **Edge:** `Failed to load resource: the server responded with a status of 404 (File not found)`

## Result

**FAIL** — Chrome, Firefox, and Edge must all pass before the Web preview is promoted.
