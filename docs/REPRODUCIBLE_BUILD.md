# Reproducible Build Instructions

## One-Command Rebuild

```bash
git clone <this-repo> sovereign-apollo
cd sovereign-apollo
npm ci                # frozen lockfile
npm run fetch:lumi    # pin Luminary099 commit + fetch artifacts
npm run verify:artifacts  # SHA256 check — fails on drift
npm run build         # tsc -p tsconfig.json → dist/
npm test              # deterministic replay + AGC unit tests
npm run replay:mission -- --check-hash  # verifies final hash
```

## Prerequisites

- Node 18+ (tested 18,20,22)
- SHA256 tool (Node crypto, no external)
- Optional: Lean 4 (for `formal/`)

## Artifact Verification

- Registry: `evidence/SOURCE_REGISTRY.json` lists every file + expected SHA256
- Originals: `evidence/artifacts/Luminary099/` (101 `.agc` files) — read-only
- Script: `scripts/verify-artifacts.ts` canonicalizes + hashes; mismatch → exit 1

```bash
npm run verify:artifacts
# ✓ 101 files verified
# ✓ git pin: chrislgarry/Apollo-11@<sha>
```

## Determinism

- `src/physics/engine.ts`: fixed dt=1ms minor, 2000ms Servicer; no `Date.now()`, seeded PRNG only
- Replay hash chain: `H_n = SHA256(H_{n-1} || canonical(state_n))` saved to `replay_*.jsonl`
- Two builds on different OS → same `H_final` (checked in CI).

## Hash Pin

Luminary099 pin recorded in `evidence/SOURCE_REGISTRY.json` (`git_pin`) and `scripts/fetch-luminary.ts` lock. Update requires explicit `--update-pin` + review.

## Lean Formal

```bash
cd formal && lake build
```

## Docker (optional)

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run verify:artifacts && npm run build && npm test
```

## Offline

After `npm run fetch:lumi`, the build needs no network: all artifacts vendored, fonts local.
