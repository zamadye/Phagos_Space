# Phagos — Organic Arena Kit (Godot 4)

Implementasi environment production-ready untuk arena **2D top-down 90°** Phagos: roguelike shooter bertema sistem imun. Kit ini membangun **arena saja** — tidak ada karakter, combat, musuh, pickup, HUD, atau UI.

> Fokusnya bukan tile RPG dan bukan dungeon kotak. Semua ruang berupa chamber radial organik, terhubung spline Bezier yang melengkung, berlapis jaringan hidup, dan dapat diganti biome tanpa mengubah graph gameplay.

## Jalankan

1. Buka root proyek ini dengan **Godot 4.3+**.
2. Jalankan `scenes/main.tscn` untuk preview Heart.
3. Untuk preview organ spesifik, buka salah satu scene berikut:
   - `scenes/biome_heart.tscn`
   - `scenes/biome_lung.tscn`
   - `scenes/biome_brain.tscn`
   - `scenes/biome_marrow.tscn`

Viewport desain adalah **1920×1080** dengan `canvas_items` stretch, sehingga tetap resolution-independent. Tidak ada input/UI debug pada scene rilis.

## Web preview production

Web export memakai renderer **Compatibility / WebGL 2**, single-threaded untuk GitHub Pages dan server statis biasa. Dengan Godot 4.3+ beserta export template terpasang:

```bash
chmod +x scripts/export_web.sh scripts/preview_web.sh scripts/deploy_web_vps.sh
./scripts/export_web.sh
./scripts/preview_web.sh
```

Preview melayani `build/web` di `http://localhost:8080`. Untuk port lain, gunakan `PORT=8008 ./scripts/preview_web.sh`, atau jalankan `python3 -m http.server 8008 --directory build/web` — menjalankan HTTP server pada root repository hanya akan menampilkan source tree, bukan Godot runtime. Root `index.html` otomatis meneruskan ke `build/web/` jika build sudah tersedia. Export menghasilkan `index.html`, `phagos.js`, `phagos.wasm`, dan `phagos.pck`; custom browser loader memiliki immune core animasi, progress, serta transisi fade 320–460 ms. Detail CI, GitHub Pages, nginx/Brotli, screenshot QA, dan VPS tersedia di [`docs/WEB_DEPLOYMENT.md`](docs/WEB_DEPLOYMENT.md).

## Yang sudah diimplementasikan

- **Modular room graph**: Spawn, Combat, Elite, Shop, Upgrade, Boss, dan Secret; semua room memiliki beberapa entrance berdasarkan edge graph.
- **Organic room geometry**: kontur radial seeded, bukan persegi, dengan chamber normal 384–640 px dan Boss 1110×970 px.
- **Spline corridor extrusion**: cubic Bezier dengan lebar yang bernapas, narrowing/widening, dan side branches anatomis. Small corridor dijaga 96–160 px; normal corridor 192 px.
- **Wall stack lima lapis**: base tissue → membrane folds → micro-cracks → emissive veins → glow highlights.
- **Non-repeating floor treatment**: shader cytoplasm flow, membrane overlay, cellular noise, per-room UV seed, rotasi/offset prosedural.
- **Empat biome lengkap**: Heart, Lung, Brain, dan Bone Marrow dengan palette, pulse, density, fog, dan accent anatomy berbeda.
- **2D lighting**: capped additive `PointLight2D`, soft glows, vein pulses, cytokine / energy light nodes.
- **Parallax tiga layer**: background tissue 0.05, veins 0.15, dan floating proteins 0.30 dengan smoothing halus.
- **Decoration system**: static collagen/ridges/chunks, semi-animated proteins/bubbles/crystals, animated vesicles/oxygen/signals, plus GPU particle path dan batched CPU fallback.
- **Breakable environment props**: `BreakableProp.break_open()` menghasilkan debris, drift, dan glow fade tanpa mengikat ke combat system.
- **Camera API**: `PhagosFollowCamera` mengikuti target `Node2D`, rotasi terkunci, smoothing opsional. Preview mengikuti marker tak terlihat karena kit ini sengaja tidak membuat karakter.
- **Art pipeline**: prompt lock, 98-file manifest, PNG/alpha/seam validator, dan atlas packer dengan edge extrusion.

## Integrasi target pemain (tanpa membuat karakter)

Scene preview memakai `CameraFocus` yang tidak terlihat. Saat proyek game memasang sel imun pemainnya, cukup panggil API berikut dari host scene:

```gdscript
@onready var arena: PhagosArenaController = $PhagosArena
@onready var immune_cell: Node2D = $ImmuneCell

func _ready() -> void:
    arena.set_player_target(immune_cell)
```

Camera tetap top-down, tidak berotasi, dan smoothing sudah frame-rate independent. Untuk kembali ke marker spawn saat preview, panggil `arena.reset_camera_to_spawn()`.

## Struktur proyek

```text
assets/
  biome/              # vein / alveoli / neuron / marrow source imports
  walls/              # straight / curve / T / X / end-cap / chamber-rim art
  floor/              # 16 seamless tissue overlays
  props/              # isolated transparent props
  particles/          # 512 px particle masters
  decals/             # tears / stains / scratches / glow residue
  manifest/           # canonical 98-file art contract
shaders/
  vein_pulse.gdshader
  membrane_distort.gdshader
  cytoplasm_flow.gdshader
  glow.gdshader
  organic_wall.gdshader
materials/
  vein_pulse_default.tres
  membrane_overlay_default.tres
  soft_glow_default.tres
scenes/
  main.tscn
  biome_heart.tscn
  biome_lung.tscn
  biome_brain.tscn
  biome_marrow.tscn
scripts/
  biome_loader.gd
  room_generator.gd
  corridor_builder.gd
  prop_spawner.gd
  ... modular runtime renderers and camera support
docs/
  ASSET_GENERATION_PROMPTS.md
  TECHNICAL_DESIGN.md
  WEB_DEPLOYMENT.md
web/
  phagos_loader.html
scripts/
  export_web.sh
  preview_web.sh
  deploy_web_vps.sh
reports/
  asset_validation.json
  browser_validation.md
  screenshots/
.github/workflows/
  web-preview.yml
tools/
  validate_assets.py
  atlas_assets.py
  capture_screenshots.gd
  browser_qa.mjs
```

## Graph dan scale

```text
                 [ Secret ]
                     │
[ Upgrade ] ── [ Spawn ] ── [ Combat A ] ── [ Shop ]
      │             │              │              │
[ Combat B ] ───────┴────────── [ Elite ] ────────┤
                                    │              │
                                 [ Boss ] ◄────────┘
```

| Elemen | Implementasi scale |
|---|---:|
| Small corridor | 96–160 px, termasuk branch bronchiole/dendrite |
| Normal corridor | 192 px nominal, berosilasi secara organik |
| Large chamber | 390–610 px kontur radial |
| Boss chamber | 1110×970 px kontur radial |
| Cell decoration | kira-kira 16–64 px gameplay scale |

`RoomGenerator` menghasilkan topology yang stabil dan mudah dibaca; seed mengubah kontur, room displacement, corridor bend, lebar, pulsation phase, dan decor placement tanpa mengubah tipe room yang dibutuhkan desain.

## Biome behavior

| Biome | Visual / geometry | Shader / lighting behavior |
|---|---|---|
| Heart | maroon/crimson ventricular tissue, large vessel accents, elastic chamber rims | rhythmic brightness, scarlet vein pulse |
| Lung | teal/cyan branching paths, rounded alveoli, low-density mist | translucent membrane motion, soft fog |
| Brain | deep violet tissue, dendrite paths, neuron clusters | fast electric cyan pulses and synapse glows |
| Bone Marrow | ivory/pink cavities, stem-cell and adipose-like forms | soft warm glows, dense hematopoietic decor |

## Art source workflow

Lihat [`docs/ASSET_GENERATION_PROMPTS.md`](docs/ASSET_GENERATION_PROMPTS.md) untuk global style lock, prompt Pack A–I, naming, negative prompts, import setup, dan checklist wajib.

```bash
python3 -m pip install Pillow
python3 tools/validate_assets.py --strict --report reports/asset_validation.json
python3 tools/atlas_assets.py --page-size 8192 --padding 16
```

Runtime scene tidak menunggu placeholder bitmap: semua visual fallback dibangun oleh draw calls dan shader. Saat art final diimpor, manifest memastikan PNG source langsung bisa di-atlas tanpa rename atau clean-up manual.

## Performance contract (desktop 60 FPS)

- `BiologicalParticleField` memakai `GPUParticles2D` pada Compatibility/WebGL bila tersedia; fallback CPU tetap satu batched `CanvasItem`, bukan ratusan `Sprite2D` animated.
- Per-biome particle budget default 132 (dapat diubah pada `PhagosArenaController`).
- Point lights dibatasi default 20 dan dialokasikan room dulu, lalu corridor.
- Static room/corridor tissue digambar sekali dan hanya dynamic glow/particle yang diproses per frame.
- Satu radial light texture dipakai ulang oleh semua `PointLight2D`.
- Atlas pipeline memakai 16 px gutter + edge extrusion; source atlas output tidak di-commit.
- Tidak ada navigation/collision/combat update dalam kit arena ini. Tambahkan collision polygon atau navigation dari spline data hanya jika pemain membutuhkan sistem tersebut.

Detail render order, API, wall layers, dan extension points tersedia di [`docs/TECHNICAL_DESIGN.md`](docs/TECHNICAL_DESIGN.md).
