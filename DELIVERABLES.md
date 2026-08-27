# Sovereign Apollo — 16 Deliverables Index

| # | Deliverable | Path | Classification | Status |
|---|-------------|------|----------------|--------|
| 1 | Systems Inventory | `docs/SYSTEMS_INVENTORY.md` | DOCUMENTED 85% | ✓ |
| 2 | Source & Evidence Registry | `evidence/SOURCE_REGISTRY.json/.md` + `evidence/artifacts/` | DOCUMENTED | ✓ |
| 3 | Mission Timeline Dataset | `data/mission_timeline.json/.csv` (22 events, 195h) | RECONSTRUCTED | ✓ |
| 4 | Vehicle Architecture Diagrams | `docs/ARCHITECTURE.md` | RECONSTRUCTED | ✓ |
| 5 | AGC Architecture Reconstruction | `docs/AGC_ARCHITECTURE.md` + `src/agc/*` | DOCUMENTED/RECONSTRUCTED | ✓ |
| 6 | AGC Software Analysis | `docs/AGC_SOFTWARE_ANALYSIS.md` (101 files) | DOCUMENTED | ✓ |
| 7 | Guidance & Navigation Model | `docs/GUIDANCE_NAVIGATION.md` + `src/physics/*` | DOCUMENTED/INFERRED | ✓ |
| 8 | Telemetry Model | `docs/TELEMETRY.md` + `src/telemetry/*` + `data/telemetry_schema.json` | DOCUMENTED/MODERN | ✓ |
| 9 | Mission Control Interface Model | `docs/MISSION_CONTROL.md` + `src/telemetry/comms.ts` | DOCUMENTED/MODERN | ✓ |
| 10 | Deterministic Simulation | `src/mission/state.ts` + `src/physics/engine.ts` + `src/vehicle/*` | RECONSTRUCTED/MODERN | ✓ |
| 11 | Fault-Injection Framework | `src/replay/fault.ts` + `src/replay/fault-cli.ts` + `src/agc/executive.ts` (1202) | MODERN (based on DOCUMENTED 1202) | ✓ |
| 12 | Digital-Twin Replay Engine | `src/replay/deterministic.ts` + `src/mission/replay-cli.ts` | MODERN DESIGN | ✓ |
| 13 | Formal Verification Package | `formal/SovereignApollo/*.lean` + `docs/FORMAL_VERIFICATION.md` + `src/sovereign/verification.ts` | FORMAL THEOREM | ✓ (stubs build) |
| 14 | Sovereign Apollo Architecture | `docs/SOVEREIGN_ARCHITECTURE.md` + `src/sovereign/local-first.ts` | MODERN DESIGN | ✓ |
| 15 | Reproducible Build Instructions | `docs/REPRODUCIBLE_BUILD.md` + `package.json` + `tsconfig.json` | MODERN DESIGN | ✓ |
| 16 | Validation & Discrepancy Report | `docs/VALIDATION_REPORT.md` | RECONSTRUCTED | ✓ |

## How to Validate

```bash
npm ci && npm run verify:artifacts && npm run build && npm test && npm run replay:mission -- --check-hash
```

All 8 tests PASS, final hash `cc63e3b7...` bit-identical across runs — see `VALIDATION_REPORT`.

## Evidence Discipline

Every claim tagged per `SOURCE_REGISTRY.json`. No inference promoted to DOCUMENTED. See workflow:

```
SOURCE → EXTRACT → NORMALIZE → MODEL → IMPLEMENT → TEST → FORMALIZE → REPLAY → COMPARE
```
