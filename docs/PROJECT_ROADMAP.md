# Phagos Space — roadmap progress dan delivery gates

Tanggal baseline: **2026-10-05**

Branch kerja: `arena/01a107da-phagos-space`

Dokumen ini menjadi urutan kerja utama agar development tidak melompat-lompat antara art, gameplay, auth, dan blockchain. Setiap fase harus melewati **exit gate** sebelum fase berikutnya dianggap aktif.

## Status

- `DONE` — selesai dan sudah tervalidasi/didokumentasikan.
- `NEXT` — fase berikutnya yang boleh dikerjakan.
- `PLANNED` — sudah dirancang, menunggu dependency fase sebelumnya.
- `BLOCKED` — membutuhkan keputusan, kredensial sandbox, atau dependency eksternal.
- `OPTIONAL` — tidak boleh menghambat Web MVP.

## Aturan delivery

1. **Vertical slice lebih dulu**: satu sesi run 3D yang bisa dimainkan dari load sampai selesai lebih penting daripada banyak fitur setengah jadi.
2. **Referensi foto adalah visual source of truth** untuk zona awal: kamera, jalur, warna, skala, dan silhouette tidak boleh berubah saat fitur Web3 ditambahkan.
3. **World-space 3D wajib**: player benar-benar maju sepanjang `Curve3D`; tidak boleh fake scrolling sebagai pengganti perjalanan.
4. **Semua elemen hidup**: dinding, sel, partikel, prop, hazard, jalur, dan avatar memiliki motion layer.
5. **Server authoritative**: score, run completion, reward, referral, dan entitlement tidak dipercaya dari client Godot.
6. **Testnet sebelum mainnet**: Ronin memakai Saigon (`202601`) untuk kontrak dan hadiah RON selama development; mainnet (`2020`) hanya setelah gate security.
7. **No secrets in client**: tidak ada private key, Privy secret, Auth secret, Google service-account key, atau treasury signer di export Godot.
8. **Google Billing hanya Android**: Google Play tidak menjadi dependency Web MVP.
9. **Tidak ada deploy kontrak prematur**: kontrak baru dibuat setelah reward ledger dan product catalog stabil.

---

## Milestone utama produk

Milestone berikut adalah checkpoint produk yang harus terlihat dan dapat diuji oleh user. Fase teknis di bawahnya adalah pekerjaan yang mengantar sampai milestone tersebut tercapai.

### M1 — Arena gameplay 3D selesai dan sesuai referensi `NEXT`

**Target:** arena gameplay sudah benar-benar berfungsi, dapat dimainkan, terasa masuk ke dalam ruang 3D, dan cocok dengan foto/planning yang sudah dikunci.

**Wajib selesai:**

- [ ] Tunnel pembuluh, jalur S, rail, lighting, palette, dan framing cocok dengan `Gameplay-Arena.jpg`.
- [ ] Player benar-benar bergerak maju di world space sepanjang `Curve3D`.
- [ ] Kamera perspective third-person menjaga komposisi avatar lower-center.
- [ ] Dinding, jalur, sel, partikel, vesikel, dan hazard hidup/beranimasi.
- [ ] Arena dapat berubah texture/material/element secara halus sepanjang perjalanan.
- [ ] Ada start, active run, collision/hazard, finish, retry, dan satu sesi yang dapat diselesaikan.
- [ ] Web export dapat boot dengan `index.html`, `index.js`, `index.wasm`, dan `index.pck`.

**Exit evidence:** screenshot overlay 1024×1024, video/smoke run dari start sampai finish, dan Web debug build yang berjalan dari Python root server.

### M2 — Character dan enemies GLB terintegrasi `PLANNED`

**Target:** karakter dan musuh berada sebagai object 3D hidup di dalam arena menggunakan asset `.glb`, bukan foto statis, billboard, atau sprite 2D.

**Wajib selesai:**

- [ ] Asset GLB yang dipilih berhasil di-import Godot dan tampil sebagai `MeshInstance3D`/scene 3D.
- [ ] Character player memiliki idle, run, hit, dan transition animation yang sesuai dengan silhouette referensi.
- [ ] Enemy/patogen memiliki idle motion, movement/approach, hit/defeat, dan collision.
- [ ] Asset tanpa animation clip diberi procedural animation atau animation player tambahan.
- [ ] Material/transparency/scale asset cocok dengan lighting arena.
- [ ] Tidak ada object penting yang diganti dengan foto PNG/JPG.
- [ ] Asset licensing/attribution dicatat sebelum dipakai dalam release.

**Exit evidence:** asset inspector/import result, gameplay screenshot yang memperlihatkan player dan enemy 3D, serta test collision/animation.

### M3 — UI/UX user-friendly `PLANNED`

**Target:** user dapat memahami flow game, result, login, reward, dan store tanpa mengganggu framing arena biologis.

**Wajib selesai:**

- [ ] UI loading/boot tidak mengganggu arena setelah game siap.
- [ ] HUD gameplay minimal dan tidak menutupi komposisi foto.
- [ ] Result screen setelah satu sesi menjelaskan score, reward, dan langkah berikutnya.
- [ ] Login screen memiliki pilihan Web2 dan Web3 dengan bahasa yang jelas.
- [ ] Error, retry, wallet pending, cancelled transaction, dan network mismatch memiliki feedback.
- [ ] Reward/item/product/inventory mudah dipahami.
- [ ] Interaksi mouse, keyboard, touch, responsive layout, focus state, dan loading state diuji.
- [ ] UI tidak menampilkan jargon blockchain tanpa penjelasan user-friendly.

**Exit evidence:** user-flow test dari load → run → finish → login → reward tanpa bantuan developer.

### M4 — Login Web2 dan Web3 Ronin terintegrasi `PLANNED`

**Target:** setelah sesi selesai, player dapat login menggunakan Web2 atau Web3, lalu mendapatkan identity/reward yang benar.

**Wajib selesai:**

- [ ] Web2 username/password melalui Next.js/Auth.js.
- [ ] Web3 Ronin Stash/Privy dengan Google/email/social login.
- [ ] External Ronin Wallet extension/mobile sebagai fallback.
- [ ] Guest run dapat di-bind ke canonical `player_id`.
- [ ] JavaScriptBridge dan one-time auth ticket aman.
- [ ] Backend memverifikasi token/signature dan alamat wallet; tidak percaya data mentah client.
- [ ] Account linking, logout, reconnect, wrong chain, cancel, dan expired session diuji.
- [ ] Reward ledger/referral siap menerima source Web2 dan Web3 yang sama.

**Exit evidence:** dua test user (Web2 dan Web3) menyelesaikan run yang sama, login setelah finish, dan menerima entitlement tanpa duplicate.

---

## Current progress board

| Fase | Track | Status | Output utama |
|---|---|---|---|
| 0. Discovery & architecture lock | Semua | `DONE` | Analisis foto, kamera, 3D dynamic arena, Web runtime, Web3 research |
| 1. Godot project foundation | Game | `NEXT` | Project Godot 4.6.2, main Node3D, input, export preset |
| 2. 3D reference blockout | Visual | `PLANNED` | Tunnel, jalur S, avatar framing, overlay match |
| 3. Living dynamic arena | Visual/Tech | `PLANNED` | Shader motion, segment pooling, dynamic texture/biome |
| 4A. Character & enemy GLB integration | Game/Asset | `PLANNED` | GLB player/enemy scenes, animation, collision, material |
| 4. Playable core run | Gameplay | `PLANNED` | Player movement, hazard, collision, session selesai |
| UX. UI/UX design system | Product | `PLANNED` | HUD, result, login, reward, store, responsive states |
| 5. Web export & bridge shell | Web | `PLANNED` | `index.*`, Python root server, WebGL 2.0, JSBridge stub |
| 6. Guest run/session service | Backend | `PLANNED` | Guest run, end-session, score validation |
| 7. Web2 Auth.js login | Auth | `PLANNED` | Username/password, session, linking model |
| 8. Ronin Web3 sandbox | Web3 | `PLANNED` | Ronin Stash/Privy, external Ronin Wallet, verified address |
| 9. Reward ledger & referral | Backend/Web3 | `PLANNED` | Item/produk reward, referral, anti-duplicate |
| 10. Ronin IAP & lucky reward | Web3/Commerce | `PLANNED` | PurchaseRouter Saigon, receipt indexing, item/produk/RON testnet |
| 11. Google Play Billing | Android | `OPTIONAL` | Play Billing 8+, purchase verification, RTDN |
| 12. Airdrop/campaign claims | Web3 | `PLANNED` | Merkle claim, ERC-1155/721, campaign dashboard data |
| 13. Security/performance hardening | QA/Ops | `PLANNED` | Audit checklist, abuse controls, profiling, recovery |
| 14. Release candidate & operations | Release | `PLANNED` | Web release, Android decision, monitoring, rollback |

---

# Track A — Game 3D dan visual

## Fase 0 — Discovery & architecture lock `DONE`

### Sudah selesai

- `Gameplay-Arena.jpg` dianalisis sebagai frame kanonik 1024×1024.
- Kamera ditetapkan sebagai perspective third-person chase, avatar lower-center, mengikuti tangent jalur.
- Arena dikunci sebagai 3D, bukan game 2D; `<canvas>` hanya output HTML WebGL.
- Forward motion ditetapkan berbasis world-space `distance_s` sepanjang `Curve3D`.
- Arena dinamis ditetapkan berbasis `ArenaSegment` dan `BiomeProfile`.
- Sel, dinding, jalur, rail, partikel, vesikel, patogen, dan avatar diwajibkan memiliki motion.
- Godot 4.6.2, web debug/release non-threads, dan Sparticuz Chromium sudah dipersiapkan.
- Build/serve contract dikunci: `index.html`, `index.js`, `index.wasm`, `index.pck` di repo root dan `python3 -m http.server 8000 --bind 0.0.0.0`.
- Web2/Web3, Ronin Stash/Privy, IAP, referral, reward, dan airdrop sudah dianalisis.

### Exit gate

- Dokumen analisis visual tersedia.
- Toolchain setup dapat diulang.
- Tidak ada konflik antara server Python root dan rencana Next.js auth service.

## Fase 1 — Godot project foundation `NEXT`

### Tujuan

Membuat project Godot minimal yang dapat dibuka, dimainkan, dan diekspor tanpa detail final.

### Tasks

- [ ] Buat `project.godot` dengan renderer Compatibility.
- [ ] Buat `Main.tscn` berbasis `Node3D`.
- [ ] Tambahkan `WorldEnvironment`, `Camera3D`, input map, dan debug labels minimal.
- [ ] Tambahkan struktur folder `scenes/`, `scripts/`, `materials/`, `assets/`, `data/`.
- [ ] Buat export preset Web non-threads dengan nama output `index.html`.
- [ ] Buat export preset desktop debug untuk iterasi cepat.
- [ ] Pastikan export Web menghasilkan empat file canonical di repo root.

### Exit gate

```text
Godot editor/headless import OK
Desktop debug boot OK
Web export menghasilkan index.html/index.js/index.wasm/index.pck
Python root server dapat menemukan index.html
```

## Fase 2 — 3D reference blockout `PLANNED`

### Tujuan

Mencapai komposisi foto sebelum memasukkan gameplay kompleks.

### Tasks

- [ ] Buat `Curve3D` jalur S dengan control point yang dapat diedit.
- [ ] Buat ribbon surface salmon dan dua rail lavender sebagai geometry.
- [ ] Buat tunnel pembuluh merah yang benar-benar mengelilingi kamera.
- [ ] Pasang `CameraRig` dan avatar placeholder pada posisi lower-center.
- [ ] Set viewport 1024×1024 dan camera preset awal.
- [ ] Buat debug reference overlay hanya untuk debug build.
- [ ] Cocokkan titik hilang, rail foreground, lebar jalur, dan posisi avatar.

### Exit gate

- Screenshot 1024×1024 dapat ditumpuk dengan foto referensi.
- Avatar tidak berada di tengah vertikal.
- Jalur terlihat masuk ke kedalaman, bukan seperti sprite/billboard.
- Tidak ada void di luar dinding lumen.
- Kamera tidak free orbit.

## Fase 3 — Living dynamic arena `PLANNED`

### Tujuan

Membuat semua elemen bergerak dan membuat arena dapat berubah sepanjang perjalanan.

### Sistem

```text
ArenaSegment
├── distance_start / distance_end
├── deterministic_seed
├── BiomeProfile
├── VesselShellSegment
├── PathSurfaceSegment
├── RailSegment
├── ActorSpawnPoints
└── TransitionBlend
```

### Tasks

- [ ] Shader flow dan vertex motion untuk dinding pembuluh.
- [ ] Pulse dan UV flow tambahan untuk jalur tanpa menggantikan world motion.
- [ ] MultiMesh/GPUParticles untuk sel biru dan partikel kuning.
- [ ] Red blood cell bob/spin/wobble.
- [ ] Patogen berduri dengan idle, pulse, proximity response.
- [ ] Vesikel/amoeba dengan deformasi membran dan internal dots.
- [ ] Segment pool: segment di belakang dapat dipakai kembali di depan.
- [ ] `BiomeProfile` untuk material, palette, prop mix, lighting, animation rate.
- [ ] Crossfade texture/material antar-segment dengan transition area.
- [ ] Seed deterministic untuk screenshot regression.

### Exit gate

- Player bergerak maju dalam world space dan dapat melewati objek.
- Texture dinding/prop berubah perlahan sepanjang perjalanan.
- Tidak ada pop texture tepat di depan kamera.
- Semua visible actor memiliki motion.
- Framerate dan memory masih terukur pada WebGL 2.0.

## Fase 4A — Character & enemy GLB integration `PLANNED`

### Tujuan

Memasukkan character dan enemies sebagai asset 3D `.glb` yang hidup di dalam arena. Foto referensi hanya dipakai sebagai acuan visual, bukan sebagai object gameplay.

### Tasks

- [ ] Audit asset GLB yang akan digunakan untuk player dan enemy.
- [ ] Import scene GLB ke Godot dan cek material, scale, orientation, skeleton, dan animation library.
- [ ] Pilih player GLB yang paling dekat dengan silhouette avatar pada foto.
- [ ] Tambahkan idle, run, hit, defeat, dan transition animation player.
- [ ] Tambahkan enemy/patogen GLB dengan idle, approach, attack/hazard, hit, dan defeat.
- [ ] Untuk GLB tanpa clip, tambahkan procedural bob, pulse, rotation, atau `AnimationPlayer`.
- [ ] Buat collision 3D untuk player, enemy, collectible, dan hazard.
- [ ] Pastikan texture/material GLB tidak menjadi billboard atau foto statis.
- [ ] Optimasi mesh/material/animation untuk WebGL 2.0 dan actor pooling.
- [ ] Catat attribution/license setiap asset yang masuk release.

### Exit gate

- Player dan enemy terlihat sebagai geometry 3D asli di dalam arena.
- Semua actor utama dapat bergerak dan merespons collision.
- Screenshot/video membuktikan tidak ada foto statis yang menggantikan character/enemy.
- Import dan animation berjalan di desktop debug serta Web debug.

## Fase 4 — Playable core run `PLANNED`

### Tujuan

Membuat satu sesi run lengkap dari start sampai finish sebelum login.

### Tasks

- [ ] Player controller mengikuti jalur dan lane offset.
- [ ] Gerak maju nyata berbasis `distance_s`.
- [ ] Steering kiri/kanan, collision, hazard, dan hit response.
- [ ] Spawn/pool patogen dan collectible.
- [ ] Start state, active run, pause/retry, finish state.
- [ ] Score, distance, waktu, dan alasan finish dikumpulkan client untuk dikirim ke backend nanti.
- [ ] Kamera tetap menjaga framing foto selama player bergerak.

### Exit gate

- Seorang tester dapat menyelesaikan satu run 60–90 detik.
- Player benar-benar masuk ke arena dan meninggalkan objek di belakang.
- Run dapat selesai tanpa login.
- Tidak ada reward bernilai tinggi yang diberikan client sebelum backend mengesahkan run.

## Fase UX — UI/UX design system `PLANNED`

### Tujuan

Membangun flow UI yang user-friendly tanpa merusak komposisi arena biologis. UI gameplay dibuat ringan dan hanya muncul ketika dibutuhkan; foto referensi tidak memiliki HUD besar.

### Screen/flow yang wajib ada

```text
Boot/loading
  → Arena gameplay
  → Pause/retry
  → Session result
  → Web2/Web3 login choice
  → Reward/inventory
  → Store/IAP
  → Error/pending/success states
```

### Tasks

- [ ] Buat design tokens warna, typography, spacing, button, modal, card, and state.
- [ ] Buat HUD minimal untuk score/distance/status tanpa menutupi focal composition.
- [ ] Buat result screen yang menjelaskan run, score, reward, dan CTA berikutnya.
- [ ] Buat login choice Web2 vs Web3 dengan bahasa non-teknis.
- [ ] Buat wallet pending, wrong network, cancelled signature, retry, dan expired-session state.
- [ ] Buat reward/inventory view untuk item, product, points, dan lucky reward.
- [ ] Buat store flow untuk product catalog dan payment confirmation.
- [ ] Uji keyboard, mouse, touch, focus, responsive, loading, empty, and error state.
- [ ] Uji UI dengan Web2 user, Web3 user, dan guest yang belum login.
- [ ] Pastikan modal/UI tidak mengeksekusi transaksi tanpa explicit user action.

### Exit gate

- Tester baru dapat menyelesaikan flow load → run → finish → login → reward tanpa bantuan developer.
- Semua async state memberi feedback yang jelas.
- UI tidak menutup avatar, jalur, atau focal area pada screenshot arena.
- UI berjalan di debug Web dan desktop Godot tanpa broken input.

---

# Track B — Web runtime dan identity

## Fase 5 — Web export & JavaScriptBridge shell `PLANNED`

### Tasks

- [ ] Export root menghasilkan `index.html`, `index.js`, `index.wasm`, `index.pck`.
- [ ] Jalankan server dari repo root dengan command yang dikunci.
- [ ] Pastikan response `.wasm` memiliki `application/wasm`.
- [ ] Browser load chain: HTML → JS → Engine → WASM → PCK → WebGL 2.0.
- [ ] Tambahkan bridge contract tanpa auth provider nyata:
  - `openAuth`
  - `getAuthResult`
  - `reportRunComplete`
  - `openStore`
- [ ] Gunakan relative URL dan same-origin untuk game asset.
- [ ] Capture screenshot dengan Sparticuz setelah boot.

### Exit gate

- Chromium smoke test berhasil membuka game dari root Python server.
- WebGL 2.0 menggambar arena 3D.
- Bridge stub dapat mengirim event masuk/selesai run.
- Tidak ada request browser ke `localhost`/`127.0.0.1` untuk backend.

## Fase 6 — Guest run/session service `PLANNED`

### Data minimum

```text
GuestRun
├── run_id
├── client_nonce
├── arena_seed
├── started_at / ended_at
├── checkpoints
├── score / distance / finish_reason
├── reward_state
└── bound_player_id (nullable until login)
```

### Tasks

- [ ] Endpoint start guest run.
- [ ] Endpoint checkpoint/heartbeat dengan rate limit.
- [ ] Endpoint finish run dengan idempotency key.
- [ ] TTL untuk guest session yang tidak diklaim.
- [ ] Server-side validation agar score tidak dipercaya mentah.
- [ ] Response hanya memberi preview reward, bukan final entitlement.

### Exit gate

- Run satu kali tidak dapat diproses dua kali.
- Guest dapat login setelah finish lalu bind ke satu player.
- Run yang sudah dibind tidak dapat diclaim player lain.

## Fase 7 — Web2 Auth.js login `PLANNED`

### Tasks

- [ ] Next.js auth service.
- [ ] Auth.js Credentials provider username/password.
- [ ] Database `Player` dan `AuthIdentity`.
- [ ] Password hash, validation, rate limit, session cookie.
- [ ] Login, logout, session refresh, account recovery baseline.
- [ ] One-time auth ticket untuk Godot.
- [ ] Link/unlink identity dengan explicit confirmation.

### Exit gate

- Web2 user dapat login setelah run.
- Game menerima only short-lived ticket/session, bukan password.
- Refresh browser tidak membuat identity baru.
- User dapat melihat account id dan reward ledger yang sama.

## Fase 8 — Ronin Web3 sandbox `PLANNED`

### Dependency eksternal

- Ronin/Privy application access dan App ID.
- Development origin/redirect allowlist.
- Saigon testnet wallet/faucet.
- Decision apakah Stash menjadi primary atau modal fallback.

### Tasks

- [ ] Ronin Stash/Privy Google login.
- [ ] Automatic keyless Ronin address provisioning/lookup.
- [ ] Backend token verification.
- [ ] Existing Ronin Wallet extension path.
- [ ] Mobile/QR path jika target mobile Web aktif.
- [ ] Chain guard: Saigon `202601` di development.
- [ ] Nonce/signature flow untuk external wallet.
- [ ] Bind wallet identity ke canonical `player_id`.

### Exit gate

- Google user mendapat Ronin address yang sama saat login kembali.
- External Ronin Wallet dapat connect dan sign nonce.
- Backend menolak address/token palsu.
- Web3 user dapat bind guest run dan melihat reward ledger.

---

# Track C — Rewards, commerce, and campaigns

## Fase 9 — Reward ledger & referral `PLANNED`

### Reward types

```text
POINTS
ITEM_OFFCHAIN
PRODUCT_OFFCHAIN
RON
ERC20
ERC721
ERC1155
LUCKY_REWARD
```

### Tasks

- [ ] Ledger immutable/idempotent untuk pending, approved, claimed, revoked.
- [ ] Reward berasal dari run yang sudah authenticated.
- [ ] Item/produk awal dikelola off-chain agar cepat divalidasi.
- [ ] Opaque referral code.
- [ ] Satu referrer per referred player per campaign.
- [ ] Self-referral, cycle, duplicate wallet, dan abuse checks.
- [ ] Milestone referral: completed run atau qualifying purchase.
- [ ] Audit trail untuk manual adjustment.

### Exit gate

- Reward item dapat diberikan lintas login Web2/Web3 melalui `player_id` yang sama.
- Referral tidak double-count.
- User dapat melihat alasan dan status reward.
- Claim endpoint aman diulang tanpa duplicate grant.

## Fase 10 — Ronin IAP & lucky reward `PLANNED`

### Urutan aman

1. Product catalog off-chain.
2. Pending order dibuat backend.
3. User melakukan transaksi di Saigon.
4. Backend memverifikasi receipt/event.
5. Item/product diberikan.
6. Baru aktifkan `LUCKY_REWARD` dengan campaign limit.
7. RON reward hanya testnet sebelum mainnet gate.

### Contract boundary

```text
PurchaseRouter
├── productId / versioned price
├── clientNonce / orderId
├── purchase(...)
├── PurchaseCreated event
├── pause/emergency control
└── multisig treasury control
```

### Tasks

- [ ] Deploy minimal PurchaseRouter ke Saigon.
- [ ] Source verification dan ABI versioning.
- [ ] Contract event indexer.
- [ ] Receipt confirmation/reorg policy.
- [ ] Idempotency chain + tx hash + log index.
- [ ] Item product purchase end-to-end.
- [ ] Lucky item/product campaign.
- [ ] Lucky RON testnet campaign dengan rule dan cap.
- [ ] Refund/failed transaction handling.

### Exit gate

- User tidak mendapat item sebelum receipt tervalidasi.
- Replay transaction tidak memberi reward dua kali.
- Wrong chain, wrong contract, wrong amount, dan wrong product ditolak.
- Admin contract dikontrol multisig/pause path.

## Fase 11 — Google Play Billing `OPTIONAL`

### Kondisi mulai

Fase ini hanya dimulai apabila Android/Google Play menjadi target rilis. Tidak boleh menghambat Web + Ronin MVP.

### Tasks

- [ ] Godot Android plugin/bridge ke Play Billing 8+.
- [ ] Product catalog di Play Console.
- [ ] Obfuscated account id dari canonical `player_id`.
- [ ] Purchase token dikirim ke backend.
- [ ] Verify `PURCHASED`, bukan `PENDING`.
- [ ] Acknowledge/consume dari backend.
- [ ] RTDN dan voided/refund handling.
- [ ] Shared entitlement dengan Web/Ronin.

### Exit gate

- Test purchase berhasil dan hanya memberi entitlement sekali.
- Pending purchase tidak memberi item.
- Refund/void mencabut entitlement sesuai policy.
- Tidak ada Ronin checkout yang melanggar Google Play policy di dalam app.

## Fase 12 — Airdrop/campaign claims `PLANNED`

### Tasks

- [ ] Campaign snapshot dari reward ledger.
- [ ] Generate leaf file dan Merkle root.
- [ ] Publish campaign metadata/root.
- [ ] Claim contract untuk ERC-1155/721 atau token reward.
- [ ] One-claim protection, expiry, pause, budget.
- [ ] Claim UI untuk Web2 player yang sudah link wallet.
- [ ] Claim UI untuk Web3 player.
- [ ] Optional VRF path untuk random giveaway jika diperlukan.

### Exit gate

- User dapat memverifikasi dirinya ada di snapshot.
- Proof salah/expired/double claim ditolak.
- Root, contract, chain, token, dan campaign id selalu cocok.
- Semua item/produk/RON yang telah claim tercatat kembali ke ledger.

---

# Track D — QA, security, and release

## Fase 13 — Hardening `PLANNED`

### Game/3D

- [ ] Screenshot overlay zona awal.
- [ ] Forward-depth test: object masuk, dilewati, keluar belakang.
- [ ] Dynamic texture transition test.
- [ ] Mobile/desktop input test.
- [ ] WebGL 2.0 performance and memory profile.
- [ ] Pool/stream segment stress test.

### Auth/API

- [ ] Origin/CORS allowlist.
- [ ] postMessage origin/source validation.
- [ ] Ticket expiry/replay test.
- [ ] Password brute-force/rate-limit test.
- [ ] Web2/Web3 account merge abuse test.
- [ ] Guest run double-submit test.

### Ronin/Commerce

- [ ] Wrong-chain/wrong-contract test.
- [ ] Duplicate receipt/log test.
- [ ] Reorg/confirmation test.
- [ ] Pause/multisig recovery drill.
- [ ] Reward budget/cap test.
- [ ] Airdrop proof fuzz test.
- [ ] Testnet → mainnet config separation.

## Fase 14 — Release candidate & operations `PLANNED`

### Web release

- [ ] Export release ke root dengan `index.*` canonical.
- [ ] Jalankan Python server command yang dikunci.
- [ ] Chromium smoke boot.
- [ ] Screenshot baseline.
- [ ] Web2 login test.
- [ ] Ronin testnet test.
- [ ] Guest → auth → reward test.

### Production readiness

- [ ] Environment variables terpisah dev/staging/prod.
- [ ] Contract addresses immutable per environment.
- [ ] Treasury multisig dan recovery runbook.
- [ ] DB backup dan restore test.
- [ ] Monitoring auth, RPC, receipt, reward, dan failed claim.
- [ ] Incident response untuk duplicate grant, refund, dan wallet mismatch.
- [ ] Mainnet enable flag tetap OFF sampai semua gate disetujui.

---

## Technical supporting gates

These gates support the four main product milestones above. They are implementation checkpoints, not replacements for the product milestones.

### G0 — Architecture locked `DONE`

Design, 3D direction, web runtime, server command, Web3 login/payment/reward research, dan roadmap tersedia.

### G1 — 3D visual proof

Zona awal sudah terlihat seperti foto referensi, kamera benar, jalur masuk ke kedalaman, dan semua elemen bergerak.

### G2 — Playable vertical slice

Player dapat menyelesaikan satu sesi run 3D, melihat result, lalu kembali/retry.

### G3 — Web guest-to-auth proof

Game Web dapat berjalan dari root Python server, player finish sebagai guest, lalu login Web2/Web3 melalui bridge.

### G4 — Reward proof

Authenticated player menerima item/produk dari ledger tanpa duplicate. Referral dasar bekerja.

### G5 — Ronin testnet commerce proof

PurchaseRouter Saigon berhasil memvalidasi purchase dan memberi product/item. Lucky reward masih capped dan testnet.

### G6 — Campaign proof

Airdrop Merkle claim atau reward campaign berhasil dengan proof, expiry, anti-double-claim, dan ledger sync.

### G7 — Release candidate

Web release stabil, performa terukur, auth/payment test lulus, security checklist selesai, dan keputusan Android sudah jelas.

---

## Progress update format

Setiap kali fase dikerjakan, update status dengan format berikut:

```text
Phase: Fase N — Nama
Status: NEXT | IN PROGRESS | BLOCKED | DONE
Completed:
- ...
Evidence:
- file/scene/test/screenshot/tx hash
Blockers:
- ...
Next gate:
- ...
```

Tidak ada fase yang boleh ditandai `DONE` hanya karena file sudah dibuat. Harus ada evidence berupa scene yang berjalan, screenshot comparison, test result, backend event, atau transaction/claim test yang dapat diulang.
