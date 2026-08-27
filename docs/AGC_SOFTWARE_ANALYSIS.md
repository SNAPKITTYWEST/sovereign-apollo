# AGC Software Analysis — Luminary099

> All files under `evidence/artifacts/Luminary099/` preserved verbatim. This doc is **RECONSTRUCTED** analysis.

## Inventory: 101 Files, 7 Functional Groups

| Group | Files | Key Behaviors |
|-------|-------|---------------|
| Core | EXECUTIVE, WAITLIST, INTERRUPT_LEAD_INS, T4RUPT, T6-RUPT, INTERPRETER | Multitasking, timing, VM |
| Navigation | KALMAN_FILTER, MEASUREMENT_INCORPORATION, ORBITAL_INTEGRATION, CONIC_SUBROUTINES, INTEGRATION_INITIALIZATION, LATITUDE_LONGITUDE_SUBROUTINES | State vectors, W-matrix, conic, Encke |
| Guidance | LUNAR_LANDING_GUIDANCE_EQUATIONS, ASCENT_GUIDANCE, GENERAL_LAMBERT_AIMPOINT_GUIDANCE, BURN_BABY_BURN, THROTTLE_CONTROL, SERVICER, FINDCDUW | PDI, ascent, Lambert burns |
| Control | DAPIDLER_PROGRAM, P-AXIS_RCS_AUTOPILOT, Q_R-AXIS_RCS_AUTOPILOT, TJET_LAW, DAP_INTERFACE_SUBROUTINES, TRIM_GIMBAL_CONTROL, KALCMANU_STEERING | DAP, RCS autopilots |
| Interface | PINBALL*, DISPLAY_INTERFACE, KEYRUPT_UPRUPT, DOWN_TELEMETRY_PROGRAM, DOWNLINK_LISTS, S-BAND_ANTENNA_FOR_LM | DSKY, telemetry, comms |
| System | FRESH_START_AND_RESTART, RESTART_TABLES, RESTARTS_ROUTINE, PHASE_TABLE_MAINTENANCE, AGC_BLOCK_TWO_SELF_CHECK, ALARM_AND_ABORT, UPDATE_PROGRAM | Restarts, alarms, uplinks |
| Mission | P12, P20-P25, P30_P37, P32-P35..., P40-P47, THE_LUNAR_LANDING, P51-P53, P63-68, IMU_* | Major Modes |

## Program (Major Mode) Map

```
P00  Idle / LGC init
 P05  Prelaunch alignment (not flown LM)
 P12  Powered Ascent (surface → orbit)
 P20  Rendezvous Navigation (ground-track + optics marks)
 P22  Orbital Navigation
 P30  External ΔV (pre-thrust targeting)
 P33/34/35  Lambert intercept/rendezvous
 P40/41  SPS thrusting (CSM)
 P42  APS thrusting (LM ascent)
 P47  Thrust Monitor
 P51  IMU Orientation Determination
 P52  IMU Realign
 P57  Lunar Surface Align
 P63  Landing Braking Phase (ign → 7000 ft)
 P64  Approach Phase (pitch → landing site)
 P65  Auto Landing (obsolete) / P66 ROD + manual
 P68  Landing Confirmation
 P70/71 Service Orbit Insertion
 P76  Target ΔV (CSM active rendezvous)
 EXTENDED_VERBS (V30..V83): ground tracking, optics, etc.
```

**Sources**: `Pxx` files listed in SOURCE_REGISTRY; `EXTENDED_VERBS.agc` 262-300.

## Critical Modules Deep Dive

### EXECUTIVE (1103-1116) + WAITLIST (1117-1132)

- **DOCUMENTED**: Cooperative priority scheduler; 8 VAC slots; priority 0 highest (restart), 6 lowest (idle).
- Jobs block via `ENDOFJOB`/`CHANGEJOB`; long waits via `WAITLIST` timer queue (T5).
- **RECONSTRUCTED**: `src/agc/executive.ts` models priority queue deterministically; **INFERRED** scheduling quantum 20ms matches docs.

### INTERPRETER (1002-1094)

- **DOCUMENTED**: ~100 opcodes; 14-bit opcode + address; uses `MPAC` (7-word accum) and stack; `VAC` per job.
- Vector ops double-precision (DP = 28b: sign + 14+14). Example sequence from LUNAR_LANDING:
  ```
  VLOAD   RN        # conical? actually position
  VSU     VTARGET
  UNIT
  DOT     VN
  ...
  EXIT
  ```
- **RECONSTRUCTED**: `src/agc/interpreter.ts` implements DP arithmetic in 1's complement, preserves overflow semantics.

### SERVICER (857-897) — 2-sec Cycle

- **DOCUMENTED**: The heart of powered flight. Called every 2 seconds via WAITLIST. Tasks:
  1. `PIPA` reading (ΔV)
  2. State vector update (`ORBITAL_INTEGRATION` → `MEASUREMENT_INCORPORATION`)
  3. Guidance equations (`LUNAR_LANDING_GUIDANCE_EQUATIONS` or `ASCENT_GUIDANCE`)
  4. Throttle (LM) via `THROTTLE_CONTROL_ROUTINES` 793-797
  5. Attitude error to `FINDCDUW` → DAP
  6. Telemetry scheduling
  7. `ENDOFJOB` → sleep 2s
- **RECONSTRUCTED**: Deterministic loop in `src/physics/engine.ts` drives Servicer tick.

### LUNAR LANDING GUIDANCE (798-828)

- **DOCUMENTED**: Polynomial guidance: `desired acceleration = f(position, velocity, time-to-go)`
- Phases P63/P64 equations: quadratic in time; target redesignation (N69) handled.
- `THROTTLE_CONTROL`: DPS throttle computed from `FC`, `ALPHAM`, `THROTTLE`; limits 10%–94% (later 57%).
- **RECONSTRUCTED**: `src/physics/propulsion.ts` ports throttle law; compared vs Luminary099 constants in `FIXED_FIXED_CONSTANT_POOL`.

### DAP (Digital Autopilot)

- Files: `DAP_INTERFACE_SUBROUTINES` 1406-1409, `DAPIDLER_PROGRAM` 1410-1420, `P-AXIS_RCS_AUTOPILOT` 1421-1441, `Q_R-AXIS_RCS_AUTOPILOT` 1442-1459, `TJET_LAW` 1460-1469, `KALCMANU_STEERING` 365-369
- **DOCUMENTED**: Phase-plane logic, deadbands, rate damping; `TJETLAW` selects jets to minimize fuel (rotational dynamics via `LEM_GEOMETRY` 320-325).
- **RECONSTRUCTED**: Simplified in `src/physics/control.ts` as PD controller with documented deadbands.

### DOWNLINK (193-205 + 988-997)

- **DOCUMENTED**: 100-word downlists, switched by program; `DNECADR` points to list; synced every 20ms at T4RUPT; 51.2 kbps.
- Lists: Cost +1 (nominal), Cost +2 (update), Orbital, Powered Flight — see `DOWN_TELEMETRY_PROGRAM.agc`.
- **RECONSTRUCTED**: `src/telemetry/downlink.ts` models lists as typed frames; CCSDS-like wrapper is MODERN DESIGN.

### RENDEZVOUS & NAV

- `KALMAN_FILTER.agc` 1470-1471 (W-matrix), `MEASUREMENT_INCORPORATION` 1149-1158, `ORBITAL_INTEGRATION` 1227-1248 (Encke + conic), `CONIC_SUBROUTINES` 1159-1204
- **DOCUMENTED**: 6-state vector + covariance (6×6); marks from AOT/RR; conic + numerical Encke for propagation.

### ALARMS/RESTARTS

- `ALARM_AND_ABORT` 1381-1385: POODOO (e.g., 00403: integrate overflow) vs BAILOUT/1202.
- `FRESH_START_AND_RESTART` 211-237: Capture `Z`, `BB`; walk phase table; `RESTART_TABLES` 238-243 encode resume PC per phase.
- Flight anecdote: 1202 @ 102:38:22 MET due to rendezvous radar flooding; executive overflow — verified in transcript + AGC listing **DOCUMENTED**; reproduced in fault framework **RECONSTRUCTED**.

## Constants & Flagwords

- `FLAGWORD_ASSIGNMENTS` 61-88: 40+ flags (e.g., `NEEDL`, `RNDVZFLG`, `TRACKFLG`); see `src/agc/memory.ts` mapping.
- `ERASABLE_ASSIGNMENTS` 90-152: ~600 symbols; e.g., `RN` (position), `VN` (velocity), `PIPTIME`, `TGO`.
- `CONTROLLED_CONSTANTS` 38-53 + `FIXED_FIXED_CONSTANT_POOL` 1095-1099: e.g., `HI6ZER`, `DP1/4TH`, moon μ, earth μ, `GDT1/4`.

## Verification Trail

- Each module: original preserved → extracted opcode/flag table → TypeScript normalizer → unit test vs listing
- `tests/agc/` checks TC/CCS/INDEX sequences from `AGC_BLOCK_TWO_SELF_CHECK` self-test vectors
- Discrepancies: where docs incomplete (e.g., NOR-gate timing, rope parity timing) marked **INFERRED/UNVERIFIED** in code comments
