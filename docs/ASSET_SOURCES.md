# M1/M2 asset provenance and selection

Tanggal: **2026-10-05**

Asset tidak di-download secara acak. Untuk M1, asset yang paling tepat dari repository dipakai terlebih dahulu; asset yang bentuknya tidak cocok tidak dimasukkan ke gameplay.

## Asset yang dipakai

| Asset | Penggunaan | Sumber repository |
|---|---|---|
| `assets/siderocyte.glb` | Red blood cell visual pada sebagian actor biologis | Extracted secara deterministik dari `siderocyte.zip` → `source/siderocyte.glb` |
| Procedural meshes | Tunnel, rails, player placeholder, pathogens, vesicles, particles, dan hazard | Dibuat di `scripts/main.gd` untuk M1 |

`assets/siderocyte.glb` dipakai melalui `PackedScene` preload di `scripts/main.gd`; export preset Web tidak mengecualikan file ini.

## Asset yang tersedia tetapi belum dipakai

- `creaturesenemiesreo.glb` memiliki metadata Sketchfab `Creatures>Enemies>Reo`, author James Lucino, license CC-BY-4.0. Bentuknya belum divalidasi sebagai pathogen biologis yang tepat, sehingga belum dimasukkan ke M1.
- `low_poly_animated_pokemon_cartoon_character_pack.glb` memiliki metadata Sketchfab CC-BY-4.0, tetapi merupakan Pokemon/cartoon pack dan tidak cocok dengan silhouette biological arena. Asset ini dikecualikan dari Web export.
- `lynphocyte.zip`, `white-blood-cell-development-metamyelocyte.zip`, dan `white-blood-cell-development-mylocyte.zip` masih memerlukan pipeline FBX/GLB import dan licensing review sebelum digunakan.

## Aturan download berikutnya

Jika asset repository tidak cukup, download hanya dari source yang dapat diaudit:

1. Kenney official asset page atau GitHub release resmi project.
2. Pin nama file, versi/tag, URL, ukuran, checksum, dan lisensi.
3. Uji import Godot, skala, material, animation clip, dan fit terhadap `Gameplay-Arena.jpg` sebelum asset dimasukkan ke scene.
4. Jangan memakai asset yang hanya kebetulan bernama biological tetapi silhouette, lisensi, atau formatnya tidak tepat.
