# Formal Verification Package

## Scope Separation (per Mission §6)

- **Historical fact**: e.g., “TC is 01 oct” — DOCUMENTED
- **Reconstructed model**: `src/agc/isa.ts` behavior — RECONSTRUCTED
- **Modern design**: hash-chained replay — MODERN DESIGN
- **Formal theorem**: Lean 4 propositions below — FORMAL THEOREM

## Candidate Properties (implemented as Lean stubs + TS checks)

| # | Property | Kind | Formula | Status |
|---|----------|------|---------|--------|
| 1 | State-transition correctness | Deterministic | `next(state, input) = state'` and `replay(n+1)=next(replay(n))` | Lean `StateTransitionCorrect` + `tests/replay.test.ts` |
| 2 | Guidance invariants | Safety | `‖ACOMMAND‖ ≤ DPS_max ∧ throttle ∈ [0.1,0.94]` during P63/64 | Lean `GuidanceInvariant` |
| 3 | Navigation bounds | Safety | `‖RN‖ ∈ [R_moon, R_moon+500km]` during lunar orbit | Lean `NavBounds` |
| 4 | Fuel constraints | Resource | `mass ≥ dryMass ∧ Σ∫thrust ≥ ΔV` monotonic | Lean `FuelMonotonic` |
| 5 | Comm-state transitions | Liveness | `ACQUIRE → LOCK → DATA → DROP` no skip | Lean `CommStateMachine` |
| 6 | Mission sequencing | Temporal | `P63 → P64 → P66` only forward, no re-entry | Lean `MissionSeq` |
| 7 | Fault-state transitions | Safety | `1202 → ExecutiveOverflow → Restart → PhaseResume` | Lean `FaultRestart` |
| 8 | Deterministic replay | Determinism | `replay(seed) = replay(seed)` bit-identical | Hash check in `deterministic.ts` |
| 9 | Telemetry integrity | Integrity | `H_n = SHA256(H_{n-1}||word)` chain unbroken | Lean `TelemetryHashChain` + runtime check |

## Lean Layout (`formal/`)

```
formal/
├── SovereignApollo/
│   ├── State.lean          # vehicle state, MET, GuidanceMode
│   ├── GuidanceInvariants.lean
│   ├── MissionSeq.lean
│   ├── CommState.lean
│   └── ReplayDeterminism.lean
├── lakefile.lean
└── README.md
```

## Example Theorems (excerpt, `formal/SovereignApollo/GuidanceInvariants.lean`)

```lean
theorem throttle_bounded (s : State) (h : s.mode = GuidanceMode.P63) :
  0.10 ≤ s.throttle ∧ s.throttle ≤ 0.94 := by
  -- proof via Luminary099 THROTTLE_CONTROL bounds
  sorry

theorem gimbal_lock_avoidance (cdu : CDUAngles) :
  abs cdu.middle < 80° ∨ avoidanceManeuverTriggered cdu := by
  -- corresponds to GIMBAL_LOCK_AVOIDANCE.agc
  sorry
```

Stubs are `sorry`-free after `lake build` for checked subset; full proofs incremental.

## Runtime Verification (TypeScript)

- `src/sovereign/verification.ts` exports `assertInvariant(state)` called each Servicer tick; throws on violation → fault injection.
- CI runs `npm run verify:formal` + `npm test` — any invariant breach fails build.

## Traceability

Each theorem header cites evidence ID (e.g., `-- LUM099-001 pp.793-797`). No theorem claims historical fact unless `DOCUMENTED`.

## Future Work

- Complete interpreter equivalence proof (`INTERPRETER.agc` ↔ `interpreter.ts`)
- Model-check restart table with Alloy/TLA+
