# Final Review Gate — Computational Archaeology Pipeline

> Answers the 8 gate questions plus pipeline verification per spec.

## 1. What did the TypeScript actually compute?

- AGC 1's complement arithmetic, opcode decode, CPU fetch-decode-execute, 15-bit word handling, channel I/O.
- Executive priority queue (8 VAC), Waitlist T5 sorted queue, Phase Table per job, overflow detection 1202.
- Interpreter DP vector ops: DOT, UNIT, VXM, ABVAL, VLOAD/VSU/VAD.
- Physics Euler stub `pos+=vel*dt`, `vel+=thrust/mass*dt`, mass flow `thrust/(Isp·g0)`, gravity `g*0.1`, Servicer 2-s tick accumulation.
- Orbital conic stub `r+v*dt`, Encke perturb stub, altitude, MU/R constants.
- Propulsion throttle `|a|/F` clamp 0.10–0.94, massFlow.
- DAP PD deadband 0.3°/0.3°/s, jet bit mask, gimbal `err*0.01`, gimbal lock 85°.
- Canonical state `State` with MET→seconds, vehicle/guidance/comm flags, `eventsToStates` mapping.
- Telemetry `buildFrame` + SHA256 chain, `wordsFromState`, comms state machine ACQUIRE→LOCK→DATA→DROP.
- Replay `canonical()` JSON sorted + `SHA256(prev+canonical)` chain, `replayAll()` 22 events, `verifyDeterminism` twice.
- Fault injection `novac` flood for 1202, com drop, throttle stuck, IMU drift.
- Invariants `throttle∈[0.10,0.94]` if P63/P64, `mass≥dry`.

## 2. What did the TypeScript merely display?

- DSKY `R1/R2/R3`/`VERB`/`NOUN`/`PROG` strings, `compActy`, `dispatchVerb` V37 logic (presentation).
- `LocalMissionControl` web stub (no physics).
- `replay_*.jsonl` pretty printing, `mission_timeline.csv` human CSV.
- Test harness `vitest` reporting.

## 3. What state did the glue layer introduce?

- `Map` for `ICHAN(0:77)` and `IPHASE(8)` (runtime glue).
- `JSON` field order for `canonical()` (modern convenience).
- `crypto.SHA256` hex chain (modern convenience).
- `Promise`/`async` wrappers (none actually used — CLI is sync, but potential).
- `structuredClone` for trace copy (runtime glue).
- `commander`/`process.argv` parsing (runtime glue).

All eliminated in FORTRAN (arrays, `FORMAT`, `MOD` checksum, `GOTO`).

## 4. What state was fundamental to the simulation?

- `COMMON /MSTATE/` — IMETSC, POS(3), VEL(3), AMASS, THRUST, THROTT, IGUID, IALARM, etc. — **fundamental**.
- `COMMON /AGCMEM/` — IERAS(2048), IFIXED(36864), EB/FB, ICHAN — fundamental.
- `COMMON /AGCCPU/` — A,L,Q,Z,BB,cycles — fundamental.
- `COMMON /EXEC/` — NJOBS, IPRIO, IPC, IWTIME — fundamental (mission sequencing).
- `COMMON /TIMELN/` — NEVENT, IMETEV, IVEHEV, IGUIDV — fundamental.
- Glue `Map` ordering, `JSON` key order, `SHA` hex — **not fundamental** (replaced).

## 5. Which semantics survived the port unchanged?

- All **COMPUTATION** per 03 registry: `I15ADD` end-around, `AGCSTEP` decode, `NOVAC` sort, `DOT/UNIT/VXM`, `THROTC` clamp, `DAPSTP` deadbands, `CONICP` stub, `MASSFL`, `COMUPD` thresholds, `ASSINV` checks, `FLTINS` flood.
- All **STATE** via `COMMON` (see 04).
- All **CONTROL FLOW** made explicit via `GOTO` loop (Phase 5) — formerly hidden in `DeterministicReplay.step` callbacks.
- Numerical constants (08) and units/frames (09) preserved.

## 6. Which semantics required approximation?

- SHA256 → `MOD(prev*31+IMETSC+AMASS, 1e9+7)` — determinism preserved, crypto strength not.
- JSON → `A9 1X I8 ...` fixed-format — fields preserved, formatting different.
- `Map` → indexed arrays — functionally equivalent, different API.
- `throw 1202` → `ISTAT=1202` — control flow equivalent, different mechanism.
- DP 28-bit 1's complement scale (INFERRED) → `REAL*8` — within 1e-6, labeled.
- Euler `g*0.1` stub → same `GMOON*0.1` — preserved placeholder, not physical.
- DSKY display strings → `IVERB/INOUN` integer input — command kept, rendering dropped.

Each marked **APPROXIMATION** in 05 matrix.

## 7. Which modern runtime features were eliminated?

- Objects/generics/closures/promises/async/await
- `Map`/`Set`, garbage collection, dynamic allocation
- `JSON`, `Fetch`, `crypto`, `npm` dynamic packages
- `vite`/`tsx` loader, `vitest`, `commander`, Web APIs
- Browser DOM, `LocalMissionControl` web stub
- Replaced with: `COMMON`/`BLOCK DATA`/`GOTO`/`OPEN`/`READ`/`WRITE`/`PARAMETER`/`gfortran`.

## 8. Can the FORTRAN reproduce the canonical test vectors?

**Yes.** `scripts/differential_test.ts` 22/22 MATCH, 0 divergences, maxThrottErr 0, TS and FORTRAN determinism OK, replay identical on second run. First divergence would have been at step 8 before harness fix (TS mapping gap), now resolved. FORTRAN `TEST_TIMELINE` (22 lines) prints all varying MET correctly (verified via `test_timeline.exe`).

## 9. Can an independent reviewer trace every FORTRAN routine back to a documented TS contract?

**Yes.** Every routine header cites TS file+line and evidence ID, e.g.:

```fortran
C     THROTC — DOCUMENTED THROTTLE_CONTROL 793-797
C     Maps to src/physics/propulsion.ts:throttleCommand
```

Trace: `TYPESCRIPT` (01 map) → `REVERSE ENGINEER` (02 graph) → `COMPUTATIONAL CONTRACT` (03) → `CANONICAL STATE` (04) → `MATHEMATICAL MODEL` (08/09) → `1978 FORTRAN` (06/07) → `DETERMINISTIC REPLAY` (10/11) → `DIFFERENTIAL VERIFICATION` (12/13).

Pipeline verified end-to-end.

## Final Pipeline

```
TYPESCRIPT (18 modules, 28 elements)
    ↓ REVERSE ENGINEER (01,02)
COMPUTATIONAL CONTRACT (03, 16 contracts)
    ↓ CANONICAL STATE (04)
MATHEMATICAL MODEL (08 constants, 09 units/frames)
    ↓ 1978 FORTRAN (07, 19 files, gfortran -std=legacy 0 errors, 22/22 replay)
    ↓ DETERMINISTIC REPLAY (11, replay_out.txt)
    ↓ DIFFERENTIAL VERIFICATION (12, 0 divergences)
VERIFIED
```

**Recover the machine logic first. Then rebuild it in the language of the era — DONE.**
