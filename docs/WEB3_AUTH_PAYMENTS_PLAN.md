# Phagos Space — Web2/Web3 authentication, Ronin, IAP, referral, and rewards

> Status: research and architecture only. No wallet, payment, token, or reward contract is deployed from this repository yet.
>
> Research checked: **2026-10-05**. Ronin changed its keyless-wallet product during 2026, so this document intentionally does not use the old Waypoint integration as the new-system default.

## 1. Product flow that is now locked

The first play session is deliberately frictionless:

```text
Load Godot Web game
  → player enters the 3D arena as a guest
  → player completes one run/session
  → server closes and scores the run
  → authentication gate appears
       ├── Web2: username + password
       └── Web3: Ronin wallet / Ronin Stash
  → guest run is bound to the authenticated player
  → rewards, inventory, referrals, and store become available
```

The player is **not forced to connect a wallet before the first run**. The run is recorded as a short-lived guest session. The reward claim is locked until the run is attached to an authenticated account.

The server, not GDScript, is authoritative for:

- whether a run finished;
- score/distance/time used for a reward;
- referral attribution;
- ownership of an item or entitlement;
- whether a payment was final, pending, refunded, or already processed.

## 2. Important current Ronin finding

Ronin's official documentation now states that **Ronin Waypoint is Ronin Stash**, powered by Privy. The migration announcement required Waypoint users to migrate assets to Stash or a seed-phrase wallet by September 30, 2026. Therefore:

- New work must use the current **Ronin Stash/Privy direction**, not start from the legacy `@sky-mavis/waypoint` flow.
- A Google/social login can create a keyless Ronin wallet/address through the Stash/Privy route.
- The user must understand the trade-off: a keyless/social wallet does not expose a normal private key or recovery phrase; losing the social account/recovery method can mean losing access. A traditional Ronin Wallet seed-phrase wallet remains a separate option.
- Existing seed-phrase Ronin Wallet users still need a normal external-wallet connection path.

Sources:

- [Ronin Waypoint is now Ronin Stash](https://blog.roninchain.com/p/ronin-waypoint-is-now-ronin-stash)
- [Ronin documentation notice and Privy direction](https://docs.skymavis.com/mavis/ronin-waypoint/overview)
- [Ronin support: social/MPC wallet vs seed-phrase wallet](https://support.roninchain.com/hc/en-us/articles/25472945752219-Understanding-The-Differences-Between-Social-Email-Login-Secret-Recovery-Phrase-Option-in-Ronin-Wallet)

## 3. Recommended login architecture

### 3.1 One canonical player identity

Use one internal `player_id`, with multiple authentication identities attached to it. Never use an email address or a Ronin address as the primary database identity.

```text
Player
├── player_id (internal UUID)
├── display_name
├── created_at / status / age_gate_state
├── Web2CredentialIdentity
│   ├── username_normalized
│   └── password_hash
├── RoninStashIdentity
│   ├── privy_user_id / verified_subject
│   ├── ronin_address
│   └── chain_id
├── RoninExternalWalletIdentity
│   ├── ronin_address
│   └── wallet_provider
├── GuestRuns
├── Referrals
├── Entitlements
└── Purchases
```

A player may start Web2-only, Web3-only, or link both later. Linking an already-existing Web2 and Web3 account must require an explicit authenticated merge flow; an address or username must never silently overwrite another account.

### 3.2 Web2 option: Next.js + Auth.js Credentials

The Web2 option will be implemented in the Next.js auth service using the Auth.js Credentials provider or an existing credential service behind it. Auth.js officially supports arbitrary credentials such as username/password; Next.js also recommends using an authentication library and hashing stored passwords.

Rules:

- validate username and password on the server with a schema;
- store only a slow password hash, never plaintext or reversible encryption;
- use an Argon2id/bcrypt-compatible password service selected during implementation;
- use a database-backed session or an encrypted HttpOnly session cookie;
- set `Secure`, `HttpOnly`, `SameSite=Lax/Strict`, expiry, rotation, and logout invalidation correctly;
- add login rate limiting, generic failure messages, audit logging, and account recovery/MFA as a later hardening phase;
- never pass `password_hash`, session secrets, or provider tokens into Godot or a client component.

Auth.js source references:

- [Credentials provider](https://authjs.dev/getting-started/providers/credentials)
- [Auth.js session strategies](https://authjs.dev/concepts/session-strategies)
- [Next.js authentication guide](https://nextjs.org/docs/app/guides/authentication)

### 3.3 Web3 option: Ronin Stash first, external Ronin Wallet fallback

The Web3 button should open one friendly Ronin flow with two choices inside it:

1. **Ronin Stash — Continue with Google/email/social**
   - current keyless onboarding path;
   - Privy-powered wallet and login;
   - automatically provisions or returns the user's Ronin address according to the configured Stash/Privy app;
   - user signs a transaction only when a purchase, claim, or other wallet action is explicitly requested.

2. **Ronin Wallet — Connect existing wallet**
   - desktop injected provider using Ronin's current EIP-6963/Tanto Connect path;
   - mobile/in-wallet browser or QR/deep-link path using the supported connector;
   - keeps the user's existing seed-phrase wallet separate from the keyless Stash wallet.

For a new Next.js shell, the likely browser stack is:

```text
Ronin Stash / Privy React SDK
+ @sky-mavis/tanto-connect for external Ronin Wallet
+ viem/wagmi for EVM reads and contract calls
```

The current Tanto docs describe Ronin Wallet, WalletConnect, injected wallets, and a React widget powered by Wagmi. The keyless configuration must be verified against the current Ronin Stash/Privy onboarding before production; we must not blindly copy an old Waypoint `clientId` flow.

Relevant references:

- [Tanto Widget](https://docs.skymavis.com/ronin/wallet/tutorials/tanto-widget)
- [Ronin Wallet injected provider/EIP-6963](https://docs.skymavis.com/ronin/wallet/tutorials/connect-web)
- [Privy Google OAuth](https://docs.privy.io/authentication/user-authentication/login-methods/oauth)
- [Privy React quickstart and automatic embedded wallets](https://docs.privy.io/basics/react/quickstart)

### 3.4 How the Ronin address is trusted

The browser must not send only `roninAddress` and ask the server to trust it.

For Ronin Stash/Privy:

1. the user signs in with Google/email/social through the Privy-powered flow;
2. the client obtains a short-lived Privy access/identity token;
3. Next.js sends that token to the backend over HTTPS;
4. the backend verifies the token with the Privy server SDK/public verification key;
5. the backend reads the verified user subject and linked wallet address;
6. the verified subject/address is linked to the internal `player_id`.

Privy documents both access-token verification and identity-token verification on the backend. Identity claims are used to prove which linked accounts belong to the authenticated user; they are not replaced by a client-supplied address.

For a seed-phrase Ronin Wallet:

1. connect the external wallet;
2. request a server-issued, single-use, expiring login nonce;
3. ask the wallet to sign a clear message containing domain, nonce, player/session id, purpose, and expiry;
4. verify the signature and checksum address on the backend;
5. consume the nonce so the proof cannot be replayed.

Reference: [Privy backend access-token verification](https://docs.privy.io/guide/react/authorization).

## 4. Godot ↔ Next.js auth bridge

The current Python static server requirement remains unchanged. The Godot Web export stays at the repository root and is served by:

```bash
cd /home/user/Phagos_Space
python3 -m http.server 8000 --bind 0.0.0.0
```

The Next.js auth service is a separate application/service. It is not served out of `.local/` and is not allowed to change the required Python server command.

Because the static game and Next.js auth service may have different local origins, the bridge will use a one-time ticket rather than sharing cookies across origins:

```text
Godot JavaScriptBridge
  → browser auth adapter opens Next.js auth UI
  → auth UI completes Web2 or Ronin flow
  → Next.js creates one-time login_ticket bound to guest_run + nonce
  → auth UI sends only ticket via postMessage to exact game origin
  → game exchanges ticket with backend
  → backend returns short-lived game session / opaque session id
  → Godot resumes reward claim UI
```

Security rules:

- strict allowlisted `targetOrigin`, never `*`;
- validate `event.source`, origin, state, nonce, expiry, and ticket status;
- ticket is one-use and short-lived;
- do not put Privy app secrets, Auth.js secrets, wallet private keys, or Google Play service-account keys in the Godot export;
- all browser-to-backend calls use HTTPS in production and exact CORS allowlists;
- JavaScriptBridge methods have a narrow allowlist: `openAuth`, `getAuthResult`, `openStore`, `openWallet`, `reportRunComplete`.

## 5. Run/session state machine

```text
GUEST_BOOT
  → RUN_ACTIVE
  → RUN_FINISHED
  → REWARD_LOCKED
  → AUTH_REQUIRED
       ├── WEB2_AUTH_PENDING → AUTHENTICATED
       └── RONIN_AUTH_PENDING → AUTHENTICATED
  → RUN_BOUND_TO_PLAYER
  → ENTITLEMENTS_SYNCED
  → REWARD_CLAIMED / STORE_AVAILABLE
```

`GuestRun` should contain:

- random `run_id` and server nonce;
- player/client version and arena seed;
- start/end timestamp;
- server-observed checkpoints or signed progress events;
- score, distance, and completion reason;
- reward eligibility state;
- binding status and expiration.

The client can display score immediately, but the backend recomputes or validates high-value reward eligibility. This prevents editing the Godot JavaScript or calling the reward endpoint with an arbitrary score.

## 6. IAP/payment strategy

### 6.1 Payment matrix

| Platform | Recommended payment rail | What it can grant |
|---|---|---|
| Web browser | Ronin smart-contract payment using Ronin Stash or external Ronin Wallet | game item, consumable, NFT, or other eligible entitlement |
| Android app distributed through Google Play | Google Play Billing | digital coins/items, consumables, non-consumables, subscriptions |
| Web-only content | Ronin/web checkout or another web payment service after policy review | web entitlement, never assumed to be Google Play purchase |

Google Play Billing is an Android app service; it is not available as a native billing API inside the Godot Web export. If we later ship an Android build, the Godot Android shell needs a BillingClient plugin/bridge and the secure backend remains the entitlement authority.

### 6.2 Ronin payment design

Do not treat a bare transfer to the treasury wallet as a complete purchase. The server needs product semantics and replay protection.

Proposed first contract boundary:

```text
PurchaseRouter
├── productId → fixed versioned price / currency
├── purchase(productId, quantity, clientNonce)
├── payment token or native RON value
├── emits PurchaseCreated(orderId, buyer, productId, quantity, amount)
├── pause/emergency controls
└── treasury withdrawal controlled by multisig
```

Server flow:

1. backend creates an internal pending order with product, price, chain, and expiry;
2. frontend builds the exact contract call for that order;
3. user confirms in Ronin Stash or Ronin Wallet;
4. backend watches the transaction/receipt and verifies chain id, contract address, event, buyer, amount, product, nonce, and confirmation policy;
5. backend inserts an idempotent purchase record keyed by chain + tx hash + log index/order id;
6. only then does it grant the entitlement.

Start with Saigon testnet (`202601`) and move to Ronin mainnet (`2020`) only after contract review and end-to-end replay/refund tests. The contract must be source-verified, use a multisig for privileged roles, and follow Ronin's smart-contract guidelines.

RON can be used for a simple first purchase. ERC-20 payment, gas sponsorship, batched calls, and stable-value pricing are later decisions; they should not be mixed into the first contract until the user experience and accounting model are proven.

References:

- [Ronin chain IDs and Web SDK wallet provider](https://docs.skymavis.com/mavis/ronin-waypoint/reference/web-sdk/web-standard)
- [Ronin smart contract guidelines](https://docs.roninchain.com/developers/smart-contracts/guidelines)
- [Ronin deploy quickstart](https://docs.roninchain.com/developers/quickstart/deploy)

### 6.3 Google Play Billing design

For a Play-distributed Android app, virtual currency, lives, characters, avatars, and other digital items generally fall under Google Play's billing requirements. The Android app must:

1. query products from Play Console;
2. launch the Play purchase flow;
3. send the purchase token to the backend;
4. let the backend verify the token with the Google Play Developer API;
5. grant entitlement only for `PURCHASED`, never `PENDING`;
6. acknowledge non-consumables/subscriptions or consume consumables on the backend;
7. process Real-time Developer Notifications and voided/refunded purchases;
8. use an obfuscated account id so the purchase maps to the same canonical `player_id`.

As of the checked 2026 documentation, new apps and updates must use Play Billing Library 8 or later under the current rollout/deprecation guidance. The exact version and regional alternative-billing eligibility will be checked again when the Android export is started.

A Ronin payment button must not be placed inside the Play Android purchase flow as a casual bypass. Alternative billing programs are region-, enrollment-, and policy-dependent. The safe default is Google Play Billing for digital goods in the Play app and Ronin payments for the Web version, with shared backend entitlements.

References:

- [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en)
- [Google Play Billing integration](https://developer.android.com/google/play/billing/integrate)
- [Google Play Billing security and verification](https://developer.android.com/google/play/billing/security)
- [Google Play Billing backend](https://developer.android.com/google/play/billing/backend)
- [Real-time developer notifications](https://developer.android.com/google/play/billing/rtdn-reference)

## 7. Referral system

Referral attribution is primarily an off-chain business rule and should not be implemented as a smart contract loop over every user.

Proposed rules:

- every player receives an opaque referral code, not a raw wallet address;
- the referred player enters the code before or during account creation;
- attribution is immutable after the first accepted relationship;
- self-referral, cycles, duplicate device/account abuse, and repeated wallet linking are rejected;
- a referral reward is pending until the referred player completes a qualifying event, such as one completed run or one verified purchase;
- reward eligibility is calculated by a server job with an audit trail;
- claim windows, maximums, region/age restrictions, and anti-sybil checks are explicit campaign configuration;
- a user can see which reward is pending, approved, claimed, expired, or rejected.

A referral table should include `referrer_player_id`, `referred_player_id`, `campaign_id`, `source_code`, `created_at`, `qualified_at`, `reward_state`, and a unique constraint preventing multiple referrers for one player/campaign.

## 8. Airdrop and reward types

### 8.1 Reward ledger first

All reward types should first pass through one internal ledger:

```text
RewardLedgerEntry
├── player_id
├── campaign_id
├── reward_type
├── amount / item_id / token_id
├── source_run / referral / purchase
├── pending → approved → claimed/revoked
├── chain_id / contract / tx_hash (if on-chain)
└── immutable audit metadata
```

This lets one player receive an item from a Web2 run and later claim an NFT with a Ronin wallet without duplicating rewards.

Initial supported enum:

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

Dalam konteks Phagos Space, istilah “equity” yang dimaksud adalah **value/reward di dalam game**, bukan saham perusahaan atau kepemilikan bisnis. Bentuknya dapat berupa item, produk/game entitlement, atau RON sebagai hadiah keberuntungan. `LUCKY_REWARD` harus tetap memiliki campaign rule, batas hadiah, odds/transparansi, anti-abuse, dan pencatatan ledger yang jelas. Untuk hadiah RON, fase development memakai Saigon testnet; mainnet baru boleh setelah kontrak, treasury, dan aturan kampanye lolos review.

### 8.2 Item rewards

The most user-friendly first version is:

- server-ledger item for non-tradable gameplay items;
- ERC-1155 for repeatable item types/quantities;
- ERC-721 for unique collectibles;
- item ownership synchronized into the same account, with wallet linking required only when the item is minted/claimed on-chain.

### 8.3 Token/NFT airdrop

For a campaign with a known recipient snapshot, use a claim-based Merkle distribution rather than writing every address into storage:

```text
snapshot → canonical leaf file → Merkle root
         → publish root + campaign metadata
         → user proves eligibility
         → contract verifies proof
         → mark leaf claimed
         → transfer/mint reward
```

Required controls:

- campaign id, token contract, chain id, root, start/end time, and total budget;
- one-claim protection and replay-safe leaf encoding;
- pause/emergency stop and a multisig-controlled admin;
- published claim dataset/root so users can independently verify inclusion;
- contract source verification on Ronin;
- no unbounded arrays or user-controlled loops;
- audit and test against proof collisions, wrong token/chain, double claim, and admin abuse.

For randomized giveaway selection, use a deterministic off-chain draw with published input or Ronin VRF rather than `block.timestamp`/`blockhash` as randomness. Ronin publishes a VRF integration path for random NFT minting; it will only be used after checking current contract addresses and gas requirements.

References:

- [OpenZeppelin Merkle airdrop workshop](https://www.openzeppelin.com/news/workshop-recap-building-an-nft-merkle-drop)
- [Ronin VRF](https://docs.roninchain.com/developers/tools/vrf)
- [Ronin smart-contract guidelines](https://docs.roninchain.com/developers/smart-contracts/guidelines)

## 9. Backend services to prepare later

```text
Next.js app / auth UI
├── Auth.js Credentials (Web2)
├── Privy/Ronin Stash adapter (Web3 keyless)
├── Ronin Wallet connector UI (external wallet)
├── postMessage + one-time ticket bridge
└── account linking UI

Backend/API
├── player and auth identity service
├── guest run/session service
├── reward/referral ledger
├── Ronin receipt/indexer worker
├── Google Play purchase verifier + RTDN handler
├── entitlement service
├── campaign/airdrop service
└── fraud/risk/audit service

On-chain Ronin
├── PurchaseRouter
├── optional ERC-20
├── ERC-721/ERC-1155 item contracts
├── Merkle claim distributor
└── multisig/admin/timelock controls
```

No server private key is held in the Godot client. A backend worker may use a dedicated treasury/minting signer only behind a multisig/HSM or managed key policy; it must not use the user's wallet key.

## 10. Implementation phases

1. **Identity skeleton** — define `Player`, `AuthIdentity`, `GuestRun`, sessions, and account-linking constraints.
2. **Guest run gate** — allow one run, close it server-side, and show auth gate only after completion.
3. **Web2 auth** — Next.js/Auth.js Credentials with hashed password and secure session.
4. **Ronin Stash/Privy sandbox** — obtain current Ronin/Privy app access, configure Google login, create a test Ronin address, verify backend tokens.
5. **External Ronin Wallet** — add extension/mobile connector fallback and nonce/signature verification.
6. **Godot bridge** — implement the narrow `JavaScriptBridge` contract and one-time ticket exchange.
7. **Reward ledger/referral** — grant testnet/off-chain items after an authenticated run and verify anti-duplicate rules.
8. **Ronin IAP sandbox** — deploy/test `PurchaseRouter` on Saigon, index receipts, and grant an item only after final verification.
9. **Android billing adapter** — only when Android distribution is requested; implement Play Billing 8+ and backend verification/RTDN.
10. **Airdrop campaign** — build Merkle snapshot/claim flow after ledger and identity linking are stable.
11. **Lucky reward gate** — hadiah item/produk/RON hanya aktif setelah campaign rule, odds/eligibility, anti-abuse, dan ledger diuji.
12. **Production hardening** — contract review/audit, source verification, multisig, monitoring, fraud controls, and disaster recovery.

## 11. Decisions that must be confirmed before coding the integration

1. Should Web3 login show **Ronin Stash with Google/email** as the primary button and **existing Ronin Wallet** as a fallback inside the same Web3 modal?
2. Is the Web2 account allowed to link a Ronin wallet later, or must users choose one permanent login type?
3. For the first reward, should we use a simple off-chain item/points ledger before deploying any token/NFT contract?
4. For lucky rewards, should the first campaign distribute only items/products, or also include a small Saigon-testnet RON path?
5. Is Android/Google Play an immediate target, or should phase one support Web + Ronin only?
