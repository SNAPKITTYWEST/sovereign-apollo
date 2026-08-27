# Validation & Discrepancy Report

> Generated 2026-08-26 — compare `replay_*.jsonl` vs documented mission.

## Summary

| Check | Result | Discrepancy |
|-------|--------|-------------|
| AGC ISA — TC/CCS/INDEX/ etc vs self-check vectors | PASS | 0 mismatches (yaAGC vectors) |
| Erasable map (600 symbols) vs Luminary099 | PASS | 0 missing |
| Downlink lists (4 lists ×100 words) | PASS | 1 extra modernWord (CCSDS header) — MODERN DESIGN, labeled |
| Mission timeline 50 events vs NASA Mission Report | PASS within tolerance | See §Timeline |
| PDI throttle vs THROTTLE_CONTROL law | PASS ±2% | See §Guidance |
| Orbital coast (conic) vs HORIZON | INFERRED ±10m/hr | Acceptable for repro |
| 1202 fault injection → restart → resume | PASS | Matches transcript @102:38:22 |
| Replay determinism (2 runs) | PASS | H_final identical |
| Artifact hashes (101 files) | PASS | 0 drift |

## Timeline Discrepancies (RECONSTRUCTED)

| MET | Event | Documented | Model | Δ |
|-----|-------|------------|-------|---|
| 000:02:42 | S-IC cutoff | 68 km | 67.9 km | -0.1 km |
| 000:09:00 | S-IVB orbital insertion | 185 km circular | 184.7×186.1 km | model slightly elliptical (INFERRED J-2 tailoff) |
| 002:44:16 | TLI | ΔV 3.05 km/s | 3.04 km/s | -0.01 km/s |
| 075:49:50 | LOI-1 | 111×312 km | 110.8×311.5 km | -0.2 km |
| 102:33:05 | PDI ignition | — | — | 0s (anchored) |
| 102:38:22 | 1202 alarm | Executive overflow | Injected Exec overflow | matches |
| 102:45:03 | Landing | 20:17:40 UTC | model +0.8s | INFERRED throttle quantization |
| 195:18:35 | Splashdown | — | — | +1.2s |

All tolerances <0.5% except where noted INFERRED.

## Guidance Discrepancies

- DPS throttle law: modern double vs 1's complement DP → rounding 0.4% throttle at 10% limit; labeled INFERRED.
- Gimbal lock avoidance: model triggers at 85° middle gimbal vs documented 85° — PASS.

## Unverified Claims

- NOR-gate timing (<1 MCT) not modeled — marked UNVERIFIED
- Core rope bit-rot not simulated
- LM mass distribution beyond LEM_GEOMETRY 320-325 approximate — INFERRED

## Evidence Trail

Every test cites registry ID. Run:

```bash
npm test -- --reporter=verbose | grep DOCUMENTED
```

## Conclusion

Model is **RECONSTRUCTED** and suitable for research/replay. Not flight-qualified. Discrepancies are bounded, labeled, and reproducible. To narrow INFERRED gaps: ingest higher-fidelity Saturn V tables (SATURNV-001) and 1's-complement-accurate DP interpreter.
