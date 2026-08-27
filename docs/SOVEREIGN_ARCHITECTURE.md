# Sovereign Apollo — Modern Architecture

> **MODERN DESIGN** — preserves Apollo engineering principles on open, local-first infra. Not claiming flight equivalence.

## Principles

| Apollo Principle | Sovereign Mapping |
|----------------|-------------------|
| Deterministic sequencing | Fixed-step physics + deterministic replay hashes |
| Restart protection (phase table) | Write-ahead log + phase checkpoints |
| Human-in-loop (DSKY) | Local WebDSKY + crew procedure timeline |
| Telemetry lists | Typed frames + hash chain |
| Ground verification | Offline MCC dashboard |
| Reproducible builds | Nix / frozen lockfile + SHA256 artifacts |

## Evaluation (per Mission §5)

| Requirement | Design | Status |
|-------------|--------|--------|
| Local-first computation | All simulation in `src/` Node/TS, no cloud calls | IMPLEMENTED |
| Deterministic simulation | Fixed dt, seeded PRNG, no Date.now() | IMPLEMENTED |
| Reproducible builds | `package-lock.json` + `scripts/verify-artifacts.ts` + `REPRODUCIBLE_BUILD.md` | IMPLEMENTED |
| Hardware abstraction | `src/vehicle/` interfaces; swap `physics/engine.ts` | IMPLEMENTED |
| Open telemetry formats | JSON frames (`data/telemetry_schema.json`), CCSDS-compatible | IMPLEMENTED |
| Local mission control | `src/sovereign/local-first.ts` Web dashboard | IMPLEMENTED |
| Offline operation | `npm run replay:mission` works air-gapped after fetch | IMPLEMENTED |
| Cryptographic artifact verification | SHA256 + hash-chained telemetry | IMPLEMENTED |
| Formal verification | `formal/SovereignApollo/*.lean` + properties | IMPLEMENTED (stub → expand) |
| Fault injection | `src/replay/fault.ts` | IMPLEMENTED |
| Digital-twin replay | `src/replay/deterministic.ts` | IMPLEMENTED |

## Stack — Sovereign [MODERN DESIGN]

```
┌─────────────────────────────────────────────┐
│  Sovereign Apollo Application               │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐  │
│  │ Digital  │ │ Mission  │ │  Local MCC  │  │
│  │  Twin    │ │ Timeline │ │  Dashboard  │  │
│  └────┬─────┘ └────┬─────┘ └──────┬──────┘  │
│       │            │              │         │
│  ┌────▼────────────▼──────────────▼────┐   │
│  │  Deterministic Replay Engine        │   │
│  │  hash(MET || state) chain          │   │
│  └────┬───────────────────────────┬────┘   │
│       │                           │        │
│  ┌────▼────┐ ┌─────────┐ ┌───────▼───┐    │
│  │ Physics │ │   AGC   │ │ Telemetry │    │
│  │ Engine  │ │  Model  │ │  +Comms   │    │
│  └─────────┘ └─────────┘ └───────────┘    │
│                                            │
│  Offline Store (SQLite / JSON) ──────────  │
│  Artifact Registry (SHA256)               │
└─────────────────────────────────────────────┘
```

### Storage

- `data/mission_timeline.json` + `data/*.json` — committed, hash-verified
- `evidence/artifacts/` — git-LFS-style but local; verified on build
- Replay logs: `replay_*.jsonl` (append-only, hash-chained)

### Determinism Guarantees

- No floating non-determinism: `engine.ts` uses fixed-step RK4, no `Math.random()` without seed
- Replay hash: `H0 = SHA256(seed); Hn = SHA256(H_{n-1} || canonical(state_n))`
- Parallel runs on same commit → bit-identical `H_final` (verified in `tests/replay.test.ts`)

### Security

- No secrets in telemetry; uplink simulation requires explicit `--allow-uplink` flag
- Artifact verification prevents silent Luminary modification

### Deployment

- Single `npm ci && npm run build` on Linux/macOS/Windows (Node 18+)
- Docker: `FROM node:20-alpine` + `npm run verify:artifacts`
- No proprietary cloud binding; optional S3-compatible sync is opt-in.

## Non-Goals

- Not flight-qualifying; no claim to meet NASA-STD-8719
- No closed-source dependencies for core loop
