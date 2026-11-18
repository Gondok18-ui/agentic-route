# Agentic Route

**Send crypto to a name, not an address.**

Agentic Route lets any holder of a Binance **Agent ID** (the soulbound `.ai` identity NFT) send BNB or ERC-20 tokens to another agent's name — `0xkylian.ai` instead of `0x3BF4…2B3D`. Humans use the web app; AI agents use the published [`skill.md`](skill.md). One immutable contract serves both.

Built for the **Binance Wallet × BNB Chain Agent ID Hackathon** (Nov–Dec 2026).

## How it works

1. The sender connects any EVM wallet (Agentic Wallet, MetaMask, …). No sign-in, no account, no backend.
2. The sender types a name. The app resolves it through the official Agent ID registry (`ownerOfHandle`) and shows the resolved address **before** anything is signed.
3. The send goes through `AgenticRoute`, which checks on-chain that the sender holds an Agent ID, then moves the funds **directly from sender to recipient in the same transaction**.

```
sender ──signs──► AgenticRoute ──forwards──► recipient
                     │  checks: sender holds Agent ID (registry)
                     │  resolves: name → address (registry)
                     └─ holds nothing, charges nothing, can stop nothing
```

## Contracts

| | BNB Chain testnet (live rehearsal) | BNB Chain mainnet |
|---|---|---|
| `AgenticRoute` | `0x41E21f1882F648d821039B5a47752F0dFE1a91c7` | *deploying ~25 Nov 2026* |
| Agent ID registry | test stand-in `0xF6532Dcf6Bb69727FA9Ee6bbB9f284E1F9ffa1f7` | official `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |

- Web app: this repo's `index.html` (GitHub Pages) — a single dependency-free static file.
- Agent interface: [`skill.md`](skill.md) — addresses, function signatures, worked examples, safety rules.
- Full design document: [`DESIGN.md`](DESIGN.md).

## Security & decentralization invariants

These are not features; they are constraints every version must keep:

1. **Zero custody.** Funds move sender → recipient atomically. The contract's own balance is always 0; it has no `receive`/`fallback`, so funds cannot even be parked in it.
2. **No control surface.** No owner, no admin, no pause, no blacklist, no upgrade, no proxy. Nobody — including the team — can stop, redirect, or tax a transaction. The registry address is immutable and publicly readable.
3. **No backend in the transaction path.** Reads are public RPC calls; signing happens only in the user's wallet. If this website disappears, the contract keeps working via BscScan, an agent skill, or a direct call.
4. **Exact approvals only.** Native sends need none; token sends use exact-amount, per-transaction approvals confirmed by the user. Never unlimited.
5. **New features = new contracts.** Deployed versions never change.

**Incident response** (by decision, there are no admin keys): prevention through a tiny audited surface → warnings at the layers we own (website, `skill.md`) → redeploy a fixed version and move the official pointers. See `DESIGN.md` §15–16.

## Tests

```bash
cd contracts
forge test                                   # 12 unit tests
forge test --match-contract ForkTest \
  --fork-url https://bsc-dataseed.binance.org  # 3 tests against the REAL mainnet registry
```

Static analysis: Slither clean of actionable findings (remaining notes are deliberate design patterns, documented in `DESIGN.md`).

## Roadmap

- [x] Contract + tests + fork verification against the real registry
- [x] Testnet deployment + live send-by-name proofs
- [x] Web app (send BNB/token, multi-chain balance view, live stats)
- [ ] Mainnet deployment + BscScan verification (~25 Nov 2026)
- [ ] Swap-to-name via PancakeSwap (v2 contract, slippage-protected)
- [ ] Multi-chain deployments — the same name resolves to the same address on every EVM chain
- [ ] 30+ Agent ID holders sending through the contract

## License

MIT
