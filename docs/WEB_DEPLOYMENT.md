# Phagos Web Preview — production deployment guide

Phagos exports to **Godot 4 Web / WebGL 2 Compatibility**. The runtime is intentionally single-threaded (`variant/thread_support=false`) so it can boot on GitHub Pages, a simple Python preview server, and standard nginx without COOP/COEP headers or `SharedArrayBuffer` requirements.

## Release contract

| Requirement | Implementation |
|---|---|
| Platform | Godot `Web` preset in `export_presets.cfg` |
| Build mode | `--export-release Web` |
| Renderer | `gl_compatibility` in `project.godot` — WebGL 2 compatible |
| Threads | disabled in preset |
| Canvas resize | Keep / `html/canvas_resize_policy=0` |
| Compression | canonical files plus Brotli `.br` sidecars emitted by `scripts/export_web.sh` |
| Browser entry | `build/web/index.html` |
| Payload naming | `phagos.js`, `phagos.wasm`, `phagos.pck` |

The `build/` directory is generated output. Do not hand-edit `build/web/index.html`; edit [`web/phagos_loader.html`](../web/phagos_loader.html), then re-export. The exporter stages its output under `build/` and replaces `build/web` only after its payload checks pass, so a missing template or failed CLI export does not erase the last working local preview.

## Local build and preview

Install Godot 4.3+ with matching export templates and Brotli, then run:

```bash
chmod +x scripts/export_web.sh scripts/preview_web.sh scripts/deploy_web_vps.sh
./scripts/export_web.sh
./scripts/preview_web.sh
```

The preview script verifies the four release payloads, exports automatically when missing, opens the browser when possible, and serves from `build/web` at:

```text
http://localhost:8080
```

It uses the requested standard command internally:

```bash
python3 -m http.server 8080
```

Modern Python maps `.wasm` to `application/wasm`. Verify it when troubleshooting:

```bash
curl -I http://localhost:8080/phagos.wasm
```

Expected files after a successful build:

```text
build/web/
├── index.html
├── phagos.js
├── phagos.wasm
├── phagos.pck
├── *.br                 # Brotli sidecars when `brotli` is installed
└── .nojekyll
```

## Loading experience

`web/phagos_loader.html` is the Web export custom shell. It contains an animated immune core, biologic orbit rings, progress reporting, clear failure messaging, and a 320–460 ms ready transition. It does not alter the arena or add in-game UI.

The shell keeps an accessible progress bar and removes itself only after Godot's `startGame()` promise resolves. It also checks browser feature availability before boot.

## GitHub Pages and CI

[`.github/workflows/web-preview.yml`](../.github/workflows/web-preview.yml) runs on `main`, `arena/**`, and manual dispatch:

1. checks out source;
2. installs Godot 4.3 plus export templates;
3. exports the Web release;
4. captures the four biome screenshots at 1920×1080;
5. validates source-art manifest status;
6. serves the release and runs Chrome, Firefox, and Edge QA;
7. uploads `web-preview.zip`, quality reports, and `build/web` as a Pages artifact;
8. deploys the exact `build/web` directory through GitHub Pages.

Repository administrators must set **Settings → Pages → Source → GitHub Actions** once. The workflow uses the official Pages deployment action and needs the `pages: write` / `id-token: write` permissions already declared in the workflow.

Artifacts:

- `web-preview.zip` — deployable static release;
- `phagos-quality-reports` — `asset_validation.json`, browser result, and biome screenshots;
- GitHub Pages artifact — the directory used by `actions/deploy-pages`.

## VPS / nginx deployment

The deploy script exports before transfer, uses checksummed `rsync --delete`, then validates/reloads nginx. No host, user, SSH key, or secret is committed to this repository.

```bash
export VPS_HOST=arena.example.com
export VPS_USER=deploy
export VPS_SSH_KEY="$HOME/.ssh/phagos_deploy"
# Optional defaults shown:
export VPS_PATH=/var/www/phagos-arena
export VPS_PORT=22

./scripts/deploy_web_vps.sh
```

`VPS_TARGET=user@host` may be used instead of `VPS_HOST`/`VPS_USER`. The remote deploy user needs write access to `/var/www/phagos-arena` and permission to run the default reload command:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Override that command if the host uses another service manager:

```bash
VPS_NGINX_RELOAD_COMMAND='sudo nginx -t && sudo service nginx reload' ./scripts/deploy_web_vps.sh
```

### nginx MIME and Brotli configuration

Canonical files must always remain available for GitHub Pages and simple static servers. On a VPS/CDN, enable precompressed sidecars for faster first loads:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}

types {
    application/wasm wasm;
}

brotli_static on;
brotli_types application/javascript application/wasm application/octet-stream;
```

If `brotli_static` is not installed, nginx serves the canonical `.js`, `.wasm`, and `.pck` files safely. Do not rewrite requests to `.br` manually without sending `Content-Encoding: br`.

## Quality gates

### Debug performance overlay

In editor/debug builds only, press **F3** to show the overlay. It reports FPS, draw calls, active lights, active particles/backend, room ID, and asset fallback state. `OS.is_debug_build()` removes it from exported release builds.

### Screenshot QA

```bash
godot --headless --path . --rendering-driver opengl3 --script res://tools/capture_screenshots.gd
```

This produces `reports/screenshots/heart.png`, `lung.png`, `brain.png`, and `marrow.png`, each normalized to 1920×1080.

### Browser QA

```bash
npm ci
npx playwright install chrome firefox msedge
python3 -m http.server 8080 --directory build/web
node tools/browser_qa.mjs --url http://127.0.0.1:8080 --report reports/browser_validation.md
```

The report gates each browser on WASM download, correct `application/wasm` MIME, absence of console/WebGL shader errors, and a 60 FPS-oriented two-second animation-frame measurement (55 FPS CI tolerance for headless browser timing).

### Art integration

`PhagosAssetResolver` reads `assets/manifest/asset_manifest.json`, recursively scans available PNG imports, and injects only declared final art. Missing, invalid, or unavailable files return `null`; floor, vein, prop, and all remaining arena visuals retain their procedural fallback and never crash a release build.
