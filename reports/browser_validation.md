# Phagos browser validation

Status: **pending automated execution**.

`tools/browser_qa.mjs` generates this file during `.github/workflows/web-preview.yml` after a real Web export is served from `build/web`. It validates Chrome, Firefox, and Edge for WASM loading, `application/wasm` MIME delivery, WebGL/shader-console errors, and a 60 FPS-oriented requestAnimationFrame gate.

Run locally after export:

```bash
python3 -m http.server 8080 --directory build/web
node tools/browser_qa.mjs --url http://127.0.0.1:8080 --report reports/browser_validation.md
```
