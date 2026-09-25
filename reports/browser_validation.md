# Phagos browser validation

Generated: 2026-09-25T23:37:13.295Z

Target URL: http://127.0.0.1:8080

Browser surface: **headed via Xvfb**. Desktop rAF gate: **≥ 55 FPS** (desktop target remains 60 FPS). A software smoke floor of **≥ 1 FPS** is active; it does not replace the desktop gate.

| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS policy | Console errors |
|---|---:|---:|---:|---:|---:|---:|
| Chrome | PASS | PASS | PASS | 5.9 | SMOKE | PASS |
| Firefox | PASS | PASS | PASS | 5.5 | SMOKE | PASS |
| Edge | PASS | PASS | PASS | 5.0 | SMOKE | PASS |

## WASM delivery
- **Chrome:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Firefox:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm
- **Edge:** 200 · application/wasm · http://127.0.0.1:8080/phagos.wasm

## Frame timing
- **Chrome:** 5.9 FPS · Google Inc. (Mesa) · ANGLE (Mesa, llvmpipe (LLVM 20.1.2 256 bits), OpenGL 4.5) · software smoke PASS (≥ 1 FPS); desktop ≥ 55 FPS remains unverified
- **Firefox:** 5.5 FPS · Mesa · llvmpipe, or similar · software smoke PASS (≥ 1 FPS); desktop ≥ 55 FPS remains unverified
- **Edge:** 5.0 FPS · Google Inc. (Mesa) · ANGLE (Mesa, llvmpipe (LLVM 20.1.2 256 bits), OpenGL 4.5) · software smoke PASS (≥ 1 FPS); desktop ≥ 55 FPS remains unverified

## Diagnostics
- **Chrome:** no console or WebGL errors observed.
- **Firefox:** no console or WebGL errors observed.
- **Edge:** no console or WebGL errors observed.

## Result

**PASS (software smoke)** — Chrome, Firefox, and Edge loaded the official Web build with valid WASM, WebGL, and clean consoles. The configured software surface cannot certify desktop 60 FPS; run this command without `--allow-software-fps` on accelerated desktop hardware for that gate.
