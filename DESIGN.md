# Agentic Route — Design Document
Agent ID Hackathon (Binance Wallet × BNB Chain) · Submission deadline: **2026-12-09 08:00 UTC (15:00 WIB)**
Status: design approved by Lian 2026-11-18 ("gas"). Name chosen by Lian 2026-11-18: **Agentic Route** (his other candidate, "Agentic Route", is reserved for the future cross-chain feature).

## 1. Product in one line
Send BNB and tokens to an **Agent ID name** (e.g. `0xkylian.ai`) instead of a raw `0x…` address.
Only Agent ID holders can send; recipients are resolved on-chain from the official registry.

## 2. Why this wins judging points
| Criterion (weight) | How AgenticRoute scores |
|---|---|
| Agent ID application depth (30%) | Agent ID is the product's core: sender gating + recipient resolution both read the official registry on-chain. Remove Agent ID and the product does not exist. |
| Practicality & feasibility (25%) | Wrong-address transfers are a real, costly pain. Names are memorable and verifiable before sending. |
| Product completion (25%) | Live and usable on day one: every visitor with an Agent ID can make a real transfer in under a minute. Not a demo shell. |
| Innovation (20%) | A name layer for agentic wallets: every AI agent already has a public name — AgenticRoute makes that name payable. Same resolved address works across EVM chains (roadmap: cross-chain). |

## 3. Verified on-chain facts (checked 2026-11-18 via cast + verified source)
- Registry: `HandleRegistry` `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` (BSC, verified, open-source).
- Stored handle has **no `.ai` suffix**: BAW's handle is the string `0xkylian`; the UI renders `handle + ".ai"`.
- `ownerOfHandle(string handle) → address` — VERIFIED: `ownerOfHandle("0xkylian")` = `0x3BF4…2B3D` (BAW). tokenId = `uint256(keccak256(bytes(handle)))`.
- `handleOf(address) → string` — reverse lookup (used to greet the connected user by name).
- `balanceOf(address) > 0` — holder check (hackathon's own documented method).
- `isValidHandle(string) → bool`; charset `[a-z0-9]`, length 3–20 (`minLen` 3, `maxLen` 20).
- The NFT is soulbound (transfers/approvals revert) — one person, one name.

## 4. User flow
1. Open the site, connect wallet (injected provider — Binance App DApp browser or MetaMask). **No QR login, no pairing codes, no server-side sessions** (hackathon red line).
2. Site reads `handleOf(connected)` → greets the user by name; reads `balanceOf` → if 0, sending is disabled with a "claim your Agent ID in the Binance App" guide.
3. User types a recipient handle (with or without `.ai`), picks asset (BNB or token) and amount.
4. UI resolves the name via `ownerOfHandle` and shows the resolved address + recipient's handle for confirmation **before** signing.
5. User confirms in their own wallet (every transfer is user-confirmed — red line respected). The Agentic Route contract forwards the funds directly to the recipient. No custody, no pooling.
6. "Recent sends" feed reads the contract's `NameSent` events — public proof of real usage.

## 5. Contract design — `AgenticRoute.sol` (BSC, Solidity 0.8.26, MIT, verified on BscScan)
- Immutable `registry` address set at deploy. **No owner, no admin keys, no pause, no upgrade, no fees.** Permissions section of the submission states this plainly (red line: documented permissions).
- `sendBNB(string calldata handle) external payable`
  - `require(registry.balanceOf(msg.sender) > 0, "Agent ID required")`
  - `to = registry.ownerOfHandle(handle); require(to != address(0), "Name not found")`
  - forward `msg.value` via `call`, require success; `emit NameSent(msg.sender, to, handle, address(0), msg.value)`
- `sendToken(string calldata handle, address token, uint256 amount) external`
  - same gating + resolution; `transferFrom(msg.sender, to, amount)` directly sender→recipient (contract never holds funds); check return value; emit event.
- Safety: no mutable state → nothing to re-enter; no approvals to AgenticRoute beyond the exact `transferFrom` amount the user signs; fee-on-transfer tokens deliver net-of-fee (disclosed in UI copy).
- Tests (Foundry): holder can send BNB; non-holder reverts; unknown name reverts; token send moves exact amounts; event fields correct; fuzz on amounts.

## 6. v2 — Swap-to-Name (after v1 is live)
- Wrap PancakeSwap V2 router inside a `NameSwap` contract with the same gating/resolution:
  `swapBNBForTokensToName(handle, tokenOut, minOut, deadline)` and token→token variant; output goes straight to the resolved recipient.
- Swap page carries a visible **risk warning** (red line for trading products).
- v2 is a stretch goal: ship only if v1 is live and stable by ~1 Dec.

## 7. Roadmap (for the submission text, not built unless time allows)
- Cross-chain sends: resolve the name once on BSC, deliver on other EVM chains via Relay's rails (the resolved address is the same on every EVM chain).
- Payment links (`namesend.app/pay/<handle>`) and agent-to-agent payments (an agent pays another agent by name — native fit for the Agentic Wallet ecosystem).

## 8. Frontend
- Static site (no backend, no database, nothing to leak): ethers.js + vanilla JS, hosted on Cloudflare Pages / GitHub Pages.
- Pages: **Send** (the product), **Activity** (on-chain event feed + live counters: unique Agent ID senders, total sends — the exact metrics the hackathon ranks), **About** (how it works, contract links, red-line compliance notes), **Get an Agent ID** (claim guide).
- Design: dark theme, gold accent, big name-first typography. The hero is the send box itself — judges can use it within 10 seconds of landing.

## 9. Timeline (WIB)
| When | Milestone |
|---|---|
| 18–19 Nov | This design; `AgenticRoute.sol` + Foundry tests |
| 20–21 Nov | BSC **testnet** deploy; frontend wired to testnet; end-to-end rehearsal with Lian's testnet wallet |
| 22–24 Nov | Fixes, polish, demo video + screenshots |
| ~25 Nov | **Mainnet deploy** + BscScan verification + site live on mainnet |
| 25 Nov – 8 Dec | Drive usage: 30+ unique Agent ID holders sending (see §10); X posts; iterate on feedback |
| ≤ 8 Dec | Submit (name, website, contract address, Agent ID usage description) — one day before the 9 Dec 15:00 WIB deadline |

## 10. Getting 30+ Agent ID holders (the eligibility bar)
- The `.ai` mint communities Lian already belongs to (PXIO, Agent Cards, and the other Agent-ID-gated projects) are full of real Agent ID holders — announce there with a live demo.
- X launch post + short demo video (send 0.001 BNB to a name, show it landing). Also eligible fodder for the hackathon's own X promotion pool.
- "First send" micro-campaign: the product is genuinely useful for dust sends between agent friends — every send is a real product use, which is exactly what the metric wants. **No wash volume, no fake accounts** (disqualification risk; also against our own rules).

## 11. Costs (Lian)
- Testnet phase: free (faucet tBNB).
- Mainnet: contract deploy + verification ≈ **0.003–0.01 BNB** total gas (needs a small top-up — BAW/EOA dust is not enough), plus whatever dust amounts he wants for demo sends. No other costs. No token, no fees charged to users.

## 12. Red-line compliance checklist (from the announcement)- [x] No web QR-code / pairing-code login for Agentic Wallet — injected wallet connect only.
- [x] No bypassing user confirmation — every transfer is signed by the user in their wallet.
- [x] No unauthorized/scheduled/bundled transfers — contract only forwards what the user sends, in the same transaction.
- [x] Contract open-source, owner permissions documented — there is no owner and no privileged function at all.
- [x] No Binance/BNB brand impersonation — product name and domain are our own.
- [x] No credential collection — the site never asks for keys, seeds, or codes.
- [x] No promised returns — copy never mentions earnings; it is a payment utility.
- [x] Trading risk warning — shown on the v2 swap page.
- [x] Not a "look up people's wallets by name" tool — resolution exists only inside the send flow to execute a payment; there is no browse/search-anyone's-wallet feature.

## 13. Multi-chain & multi-asset expansion (added 2026-11-18, Lian's request)
- **Balance dashboard (v1.5, read-only, cheap to build):** balances are public data — the dApp needs NO signature and NO approval to display them. On wallet connect (address reveal only), the frontend reads native + ERC-20 balances via each chain's RPC: BSC, Ethereum, Base, Arbitrum, and more. A message signature cannot read balances and cannot move funds; the product is stateless, so no sign-in is used at all.
- **Multi-asset on BSC (already in v1):** any ERC-20 via `sendToken`, plus native BNB. ETH/altcoins on their own chains follow with per-chain deployments.
- **Multi-chain sends (v2.5):** the same `AgenticRoute` contract deployed per chain (CREATE2 → identical address everywhere). A name resolves to the same address on every EVM chain, so "send to name" works cross-chain once deployed.
- **Gating caveat (honest):** the Agent ID registry lives on BSC, so sender-must-hold-Agent-ID can be enforced on-chain only on BSC. On other chains the check is done by the app reading the BSC registry (softer). Hackathon-counted interactions are on BSC anyway — BSC stays the priority; other chains are expansion.
- **Approval policy (hard rule):** native-coin sends need NO approval. Token sends use **exact-amount, per-transaction** approvals that the user sees and confirms in their own wallet. NEVER unlimited approvals or setApprovalForAll — those are what trigger wallet warnings, and soliciting unlimited approvals without the user's knowledge is an explicit hackathon red line (disqualification). Transparency is a feature: the UI states "exact amount only, confirmed by you, every time."

## 14. Agent interface — the skill file (added 2026-11-18, Lian's request)
Agentic Route is dual-interface: humans use the web UI; **AI agents use a published skill file**.
- Publish `skill.md` at the product domain (same pattern as pxio.fun/agent-skill.md): contract addresses per chain, function signatures (`sendBNB`, `sendToken`, swap functions), the Agent ID gating rules, worked examples, and the safety rules (exact-amount approvals only, user confirms every asset movement in their own wallet flow, never unlimited approvals).
- Agents do NOT "connect to the website" — an agent's wallet (e.g. Binance Agentic Wallet via its CLI) calls the contracts directly, exactly how Abangda minted PXIO. The web connect flow is for humans in browsers; the contract layer is for agents. One product, two doors.
- Natural-language flow this enables: user tells their agent "swap my BNB to ETH on Agentic Route" → agent reads skill.md, resolves names, prepares the call, the wallet's own preview/confirmation flow runs, then it executes and reports the tx hash.
- Pitch value: this is the Agentic Wallet ecosystem's native usage pattern — the sender is an agent holding an Agent ID, paying another agent by name. Strong material for the innovation + Agent-ID-depth scores.

## 15. Non-negotiable invariants (Lian's directive, 2026-11-18)
"Seaman dan sedesentralisasi mungkin — tidak ada yang bisa menahan dana pemilik, tidak ada yang bisa menghambat transaksi, transparan dan pure end-to-end."
1. **Zero custody, forever.** Funds move sender -> recipient inside one transaction. The contract's own balance must always be 0 (verified on testnet). No receive/fallback: plain transfers to the contract revert, so funds cannot even be parked in it.
2. **No control surface.** No owner, no admin, no pause, no blacklist, no upgrade, no proxy. Nobody — including the team — can stop, redirect, or tax a transaction. The registry address is immutable and publicly readable on-chain.
3. **No backend in the transaction path.** The frontend is a static page: reads via public RPC, signing only in the user's wallet. If the website disappears, the contract keeps working through BscScan's write UI, any agent skill, or a direct call. New features ship as NEW contracts; deployed versions never change and keep working.
4. **Approvals stay exact.** Native sends need none; token sends use exact-amount, per-transaction approvals confirmed by the user. Never unlimited.
5. **Transparency.** Verified open-source contracts, public repo, skill.md pins the official addresses so anyone can check they are talking to the real contract.
6. **Swap (v2) constraint:** one transaction straight through the DEX with user-set minimum-out; no intermediate holding by any contract of ours.

## 16. Incident response (Option A — decided by Lian 2026-11-18)
No admin keys exist, by decision. If something goes wrong, response happens at the layers we own:
1. **Prevention first:** tiny audited surface, no custody (a bug cannot trap or drain user funds; worst case is one user's own signed transaction), frozen bytecode, public testnet rehearsal before mainnet.
2. **Frontend + skill layer (minutes):** take the site down or banner a warning; update skill.md to deprecate the affected contract and pin the fixed one. Most real-world incidents live in this layer.
3. **Redeploy (hours):** ship a fixed contract version, move every official pointer (site, skill, docs, announcement posts) to it. The old contract holds nothing, so nobody's funds are stranded in it.
Rejected: pausable multisig guardian (Option B) — a pause key can hinder transactions and, if lost, could halt the product permanently; it would protect a vault that does not exist.
