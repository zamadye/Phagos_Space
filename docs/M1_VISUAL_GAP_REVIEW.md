# M1 visual gap review

Tanggal: **2026-10-05**  
Reference: `Gameplay-Arena.jpg`  
Current evidence: `evidence/m1-web-active.png`, `evidence/m1-reference-overlay.png`  
Calibration: `F3` resets/locks the canonical start zone before the `F2` overlay screenshot.

## Verdict

**Visual acceptance belum lulus.** Runtime gameplay, world-space movement, Web export, Pokemon player import, blood-flow layer, finish, dan retry sudah bekerja. Namun current arena belum cukup dekat dengan reference image untuk mengklaim visual match.

Reference harus dipakai sebagai acceptance untuk **composition dan density**, bukan hanya sebagai acuan warna merah.

## Perbedaan yang terlihat

| Area | Reference `Gameplay-Arena.jpg` | Current build | Required correction |
|---|---|---|---|
| Tunnel wall | Dinding memenuhi seluruh frame dengan serat pembuluh, lipatan organik, highlight lembut, dan depth volumetrik. | Wall terlalu flat/dark dan memiliki area kosong besar. Serat hanya terbaca sebagai garis shader sederhana. | Buat shell lebih tebal/berlapis, tambahkan serat organik, noise besar-kecil, highlight, dan fog depth yang tetap terlihat di WebGL. |
| Blue membrane cells | Banyak cluster biru menempel pada dinding di kiri, kanan, atas, dan background. | Hanya sedikit actor biru dan sebagian terlihat seperti ovoid sederhana/floating prop. | Tambahkan field actor biru yang padat, menempel pada frame tunnel, dengan scale/rotation/offset yang bervariasi. |
| Yellow particles | Partikel kuning tersebar padat mengikuti dinding dan ruang lumen. | Jumlah dan depth terlalu sedikit sehingga ruang terlihat kosong. | Naikkan density dan gunakan flow layer yang mengikuti tangent/permukaan dinding. |
| Path geometry | Jalur salmon memiliki S-curve yang jelas, melebar di foreground, dan masuk ke titik hilang dengan rail lavender terang. | Current frame sering terlihat lurus/flat; rail terlalu gelap dan path kurang memiliki bentuk organik. | Kunci camera/reference zone terlebih dahulu, lalu kalibrasi curve, rail width, foreground framing, dan path surface. |
| Glass bloodstream | Permukaan terlihat seperti cover transparan di atas lapisan sel darah merah, platelet, dan pathogen yang sangat padat. | Transparent layer sudah ada, tetapi field sel di bawahnya masih jarang dan belum menghasilkan rasa kaca biologis. | Tambahkan cell field padat, variasi red-cell mesh, depth layering, translucency, dan flow direction yang konsisten. |
| Floor props | Banyak red blood cell disc, purple organoid/vesicle, dan pathogen berduri berada di jalur serta foreground. | Props masih berupa bentuk procedural sederhana dengan distribusi sparse; foreground belum penuh. | Tambahkan prop anchors yang mengikuti curve, ukuran bertingkat, occlusion, dan hazard clusters pada foreground/midground/background. |
| Amoeba/vesicle | Ada membrane blob besar dengan internal yellow dots dan tentacle/loop forms pada dinding/jalur. | Bentuk amoeba/vesicle belum dominan dan belum mengisi landmark visual reference. | Tambahkan vesicle silhouette besar sebagai landmark, internal dots, membrane pulse, dan attachment ke tunnel/path. |
| Lighting | Reference memiliki red-pink ambient, salmon path yang bercahaya, lavender rail, dan highlight hangat pada actor. | Current build terlalu uniform dark red dengan kontras rendah. | Naikkan ambient red-pink, warm path light, lavender rail response, actor rim light, dan fog falloff. |
| Player framing | Player kecil, lower-center, terlihat masuk ke ruang biologis dan dikelilingi banyak foreground actor. | Pokemon player sudah benar secara asset, tetapi relatif terlalu dominan ketika foreground density rendah. | Pertahankan GLB intact; kalibrasi scale/camera hanya sebagai wrapper setelah environment density diperbaiki. |

## Priority order

1. **Reference camera and path blockout** — kunci titik hilang, S-curve, lebar foreground, rail lavender, dan lower-center player.
2. **Tunnel shell art pass** — ubah wall dari flat red menjadi organic vessel dengan depth, fibers, folds, blue clusters, dan yellow particles.
3. **Transparent glass bloodstream pass** — padatkan layer sel darah di bawah path; pastikan aliran tetap berjalan saat player idle.
4. **Landmark props** — red blood cells, purple discs, vesicle/amoeba blobs, dan pathogen clusters harus mengisi foreground/midground/background seperti reference.
5. **Lighting/material pass** — red-pink volumetric ambience, salmon path, lavender rails, warm highlights, dan translucent actors.
6. **Route expansion** — setelah zona awal cocok, tambahkan segment lurus, kiri, kanan, S, dan junction/cabang.
7. **GLB enemy/boss pass** — import intact GLB tanpa mengubah geometry; tambahkan skill/AI/collision melalui wrapper.

## Gate decision

- Gameplay gate: **PASS**
- Web export gate: **PASS**
- Player GLB gate: **PASS** untuk selected Pokemon character wrapper
- Blood-flow prototype gate: **PASS** secara teknis, visual density masih perlu diperbaiki
- Reference visual gate: **NOT PASS**
- M1 milestone: **IN PROGRESS**

M1 tidak boleh diubah menjadi `DONE` sebelum screenshot overlay berikutnya menunjukkan perbaikan pada path composition, tunnel density, glass bloodstream, actor landmark, dan lighting.