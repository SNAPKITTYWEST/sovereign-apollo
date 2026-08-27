# Source & Evidence Registry

> **No mythology. No invented specifications. No hidden assumptions.**

## Classification

- **DOCUMENTED** — primary historical/technical source
- **RECONSTRUCTED** — derived from documented info, independently implemented
- **INFERRED** — reasonable where docs incomplete (labeled)
- **MODERN DESIGN** — Sovereign engineering decision
- **UNVERIFIED** — insufficient evidence

## Primary Artifacts

### Luminary099 (DOCUMENTED)

- **ID**: LUM099-001
- **Source**: `https://github.com/chrislgarry/Apollo-11/tree/master/Luminary099`
- **Provenance**: MIT Museum hardcopy 1969-07-14, transcribed by Ron Burkey, assembled with yaYUL
- **Assembly**: `ASSEMBLE REVISION 001 OF AGC PROGRAM LMY99 BY NASA 2021112-061 16:27 JULY 14,1969`
- **Files**: 101 `.agc` modules, ~40k LOC, monolithic inclusion via `MAIN.agc` (no linker — punch-card deck model)
- **Preservation**: `evidence/artifacts/Luminary099/` verbatim; hashes in `SOURCE_REGISTRY.json`; verified by `scripts/verify-artifacts.ts`
- **Status**: **DOCUMENTED** — original source preserved separately from `src/agc/` modern reimplementation

File index derived from `MAIN.agc` (excerpt):

| Module | Pages | Evidence |
|--------|-------|----------|
| ASSEMBLY_AND_OPERATION_INFORMATION | 1-27 | DOCUMENTED |
| ERASABLE_ASSIGNMENTS | 90-152 | DOCUMENTED |
| EXECUTIVE | 1103-1116 | DOCUMENTED |
| INTERPRETER | 1002-1094 | DOCUMENTED |
| LUNAR_LANDING_GUIDANCE_EQUATIONS | 798-828 | DOCUMENTED |
| THE_LUNAR_LANDING | 785-792 | DOCUMENTED |
| SERVICER | 857-897 | DOCUMENTED |
| DOWNLINK_LISTS | 193-205 | DOCUMENTED |
| FRESH_START_AND_RESTART | 211-237 | DOCUMENTED |

See full 101-file index in `SOURCE_REGISTRY.json`.

## Additional Registries

- `SATURNV-001` (DOCUMENTED) — Saturn V Flight Manual SA-507, MSFC-MAN-507, IU
- `CSM-LM-001` (DOCUMENTED) — AOH CSM104/LM-5
- `GUIDANCE-001` (DOCUMENTED) — Guidance equations pp.798-828
- `TELEM-001` (DOCUMENTED) — Downlink Lists pp.193-205
- `COMM-001` (DOCUMENTED) — S-Band/MSFN

## Modern Reconstructions

- `TIMELINE-001` (RECONSTRUCTED) — `data/mission_timeline.json` from NASA Mission Report + Flight Plan
- `PHYSICS-001` (MODERN_DESIGN) — `src/physics/` deterministic engine

## Verification

```bash
npm run fetch:lumi        # fetch & pin git commit
npm run verify:artifacts  # SHA-256 check
```

Any mismatch → build fails. Original artifacts never silently modified.

## Extract → Normalize → Model Pipeline

For each subsystem we produce:

1. **SOURCE** — raw artifact pointer + hash
2. **EXTRACT** — normalized tables (e.g., erasable map, opcode table)
3. **NORMALIZE** — typed schemas (`src/agc/isa.ts`, `data/*.json`)
4. **MODEL** — executable TypeScript model
5. **IMPLEMENT** — tests
6. **FORMALIZE** — `formal/*`
7. **REPLAY** — deterministic trace
8. **COMPARE** — discrepancy report

See `docs/VALIDATION_REPORT.md`.
