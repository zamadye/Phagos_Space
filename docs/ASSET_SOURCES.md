# M1/M2 asset provenance and selection

Tanggal: **2026-10-05**

Asset tidak di-download secara acak. Untuk M1, asset yang paling tepat dari repository dipakai terlebih dahulu. Untuk M2, GLB yang sudah tersedia dipakai sebagai source visual final tanpa membongkar atau mengubah bentuk mesh/material/skeleton-nya.

## Asset yang dipakai

| Asset | Penggunaan | Sumber repository |
|---|---|---|
| `assets/siderocyte.glb` | Red blood cell visual pada sebagian actor biologis | Extracted secara deterministik dari `siderocyte.zip` → `source/siderocyte.glb` |
| `low_poly_animated_pokemon_cartoon_character_pack.glb` | Player character utama M2; bentuk unik dipertahankan karena tetap terasa biologis/organik | GLB repository, dipakai intact tanpa re-mesh, retopo, bongkar mesh, atau perubahan bentuk |
| `creaturesenemiesreo.glb` dan GLB biologis lain yang sudah tersedia | Enemy/virus/creature biologis; boss dapat memakai skeleton/rig yang tersedia | GLB repository, dipakai sebagai visual final; skill, collision, dan response ditambahkan di layer gameplay |
| `assets/vessel_wall_breathing.glb` | Modular vessel wall dengan authored folds, fibers, dan breathing shape-key animation | Dibuat melalui Blender `tools/blender/build_biological_assets.py`; asset additive, tidak mengubah GLB repository |
| `assets/pathogen_emergence.glb` | Pathogen biologis dengan spike silhouette dan animation clip untuk muncul dari wall | Dibuat melalui Blender; dipakai oleh hazard wrapper dengan spawn mode `road`, `wall_left`, atau `wall_right` |
| Procedural meshes | Rails, player placeholder M1, vesicles sementara, particles, collision, dan fallback geometry | Dibuat di `scripts/main.gd` untuk M1; tidak menjadi alasan untuk mengubah GLB final |

`assets/siderocyte.glb` dipakai melalui `PackedScene` preload di `scripts/main.gd`; export preset Web tidak mengecualikan file ini.

## Keputusan pemakaian M2

- `low_poly_animated_pokemon_cartoon_character_pack.glb` dipilih sebagai source player character. Karena file ini adalah pack multi-character, integration wrapper akan memilih satu contained character/armature yang sesuai; character yang dipilih tetap di-instantiate utuh dan tidak dipecah, di-remesh, atau di-re-export. Silhouette uniknya dipertahankan; tidak ada penggantian bentuk menjadi humanoid generik.
- `creaturesenemiesreo.glb` dan GLB biologis lain dipakai untuk enemy/virus/creature sesuai peran gameplay. Boss boleh memakai tulang/skeleton/rig yang memang sudah ada pada asset.
- Semua GLB diintegrasikan sebagai scene/visual source yang utuh. Tidak ada bongkar mesh, remesh, retopo, merge material, perubahan skeleton, atau re-export yang mengubah visual.
- Skill, hitbox, collision, AI, attack, hit reaction, VFX, dan status effect ditambahkan sebagai node/script gameplay di luar asset GLB.
- `lynphocyte.zip`, `white-blood-cell-development-metamyelocyte.zip`, dan `white-blood-cell-development-mylocyte.zip` tetap mengikuti pipeline import yang tersedia; jika dipakai, bentuk source juga tetap dipertahankan dan hanya diberi behavior tambahan.

## Source identity lock untuk GLB M2

Hash ini mengunci file yang akan di-import. Jika file berubah, lakukan review visual dan provenance ulang; jangan menimpa asset dengan export/repack yang tidak identik.

| File | Ukuran | SHA-256 |
|---|---:|---|
| `low_poly_animated_pokemon_cartoon_character_pack.glb` | 15,947,488 bytes | `354bb5b530a764935642e98a992fe4ddc7fe6992e0dd346631cde75ebbf93e22` |
| `creaturesenemiesreo.glb` | 161,348 bytes | `3b3a58ab586bebfc5c3da71741f66e3528033c197523d70e2361a14c4ef44fbc` |
| `assets/siderocyte.glb` | 112,064 bytes | `2e66bc2206b277c87f997a2cefee9ce15bcaba3eec05a5b1728eb65915e2d4c9` |
| `assets/vessel_wall_breathing.glb` | 152,744 bytes | `f17e0610eb03634e41eca6e3e8ab40b6156ccf2af2b2b62d643f1028dbb59f41` |
| `assets/pathogen_emergence.glb` | 39,032 bytes | `20f1b53ba06a31e78e36fd2b277457e4b88945f2bc33d56377156a3e72bd03d6` |

## Aturan download berikutnya

Jika asset repository tidak cukup, download hanya dari source yang dapat diaudit:

1. Kenney official asset page atau GitHub release resmi project.
2. Pin nama file, versi/tag, URL, ukuran, checksum, dan lisensi.
3. Uji import Godot, skala, material, animation clip, dan fit terhadap `Gameplay-Arena.jpg` sebelum asset dimasukkan ke scene.
4. Jangan memakai asset yang hanya kebetulan bernama biological tetapi silhouette, lisensi, atau formatnya tidak tepat.
