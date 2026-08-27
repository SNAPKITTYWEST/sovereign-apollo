# TypeScript Dependency Graph

## High-Level Orchestrator (from Phase 1)

```
                         UI (Dsky.key / LocalMissionControl — PRESENTATION)
                          │
                          ▼
               TypeScript Orchestrator (replay-cli / fault-cli)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   Mission State    Vehicle State    Guidance/Navigation
   state.ts         saturnV/csm/lm    interpreter/control
        │                 │                 │
        └─────────┬───────┴────────┬────────┘
                  │                │
              Physics            Telemetry
           engine/orbital       downlink/comms
           propulsion            │
                  │                │
                  └───────┬────────┘
                          ▼
                       Replay
                 deterministic.ts
                          │
                          ▼
                   Canonical State (State)
                          │
                     SHA256 chain
```

## Module → Module Edges (import graph, verified via grep)

```
replay-cli.ts ──→ deterministic.ts ──→ timeline.ts ──→ state.ts
                              ├──────→ downlink.ts ──→ state.ts + crypto
                              └──────→ comms.ts
fault-cli.ts ──→ fault.ts ──→ executive.ts ──→ isa.ts
             └─→ deterministic.ts
engine.ts ──→ state.ts + orbital.ts + propulsion.ts + control.ts + verification.ts
deterministic.ts ──→ timeline.ts, downlink.ts, state.ts
timeline.ts ──→ state.ts + fs
downlink.ts ──→ state.ts + crypto
comms.ts ──→ (none, self-contained state machine)
cpu.ts ──→ memory.ts + isa.ts
interpreter.ts ──→ (pure Vec ops, no deps)
executive.ts ──→ isa.ts (TIMING)
memory.ts ──→ isa.ts (CHANNELS)
verification.ts ──→ state.ts
saturnV/csm/lm ──→ (constants only)
```

No cycles. Depth 4 max (cli → replay → telemetry → state).

## Computational-Contract Dependency (Phase 2 ordering)

```
CONSTANTS (isa.ts FLAGWORDS, TIMING_MCT, CHANNELS; memory ERASABLE_MAP; physics MU_*; vehicle SATURN_V)
  ↓
VECTOR / MATRIX (interpreter.ts VLOAD/DOT/UNIT/VXM)
  ↓
MEMORY MODEL (memory.ts add/read/write/channel)
  ↓
CPU STEP (cpu.ts decode→exec) depends on MEMORY + ISA
  ↓
EXECUTIVE (executive.ts novac/waitlist/phase) depends on ISA timing
  ↓
TIME / STATE (state.ts metToString; engine.ts step)
  ↓
ORBITAL (orbital.ts conic/encke) depends on MU constants
  ↓
PROPULSION / CONTROL (propulsion.ts throttleCommand; control.ts dapStep) depends on ORBITAL state
  ↓
GUIDANCE / NAVIGATION (interpreter exec + guidance invariants verification.ts)
  ↓
TELEMETRY (downlink.ts buildFrame) depends on State
  ↓
MISSION LOOP (deterministic.ts replayAll) depends on all above
  ↓
FAULT (fault.ts inject) depends on Executive + Mission Loop
  ↓
REPLAY VERIFICATION (deterministic.ts verifyDeterminism) depends on canonical()
```

## Browser-Only / Node-Only Dependencies (must be replaced in FORTRAN)

| Feature | TS Usage | FORTRAN Replacement |
|---------|----------|---------------------|
| `fs.readFileSync` JSON | `timeline.ts:10` | `OPEN/READ` fixed-format file |
| `crypto.createHash SHA256` | `downlink.ts:10`, `deterministic.ts:40` | Simple checksum or 32-bit CRC (no crypto runtime) |
| `Map` | `memory.ts:channels`, `executive.ts:phaseTable` | Indexed arrays `ICHAN(0:77)`, `IPHASE(8)` |
| `Promise/async` | none (CLI is sync) | — sequential |
| `structuredClone` | `engine.ts:38` trace copy | Array copy loop |
| `JSON` | everywhere | `FORMAT` statements + `READ` |
| `commander` / `process.argv` | `fault-cli.ts` | `IARGC/GETARG` or positional `READ(5,*)` |
| `vitest` | tests | `PROGRAM TEST` with `IF` checks |
| `tsx` loader | runtime | `gfortran` compile |

## Porting Priority (by dependency depth × dependents × verification importance)

1. `isa.ts` + `memory.ts` (foundational, 6 dependents)
2. `state.ts` (canonical, 7 dependents)
3. `orbital.ts` / `propulsion.ts` (numerics, 2 dependents)
4. `cpu.ts` / `interpreter.ts` / `executive.ts` (AGC core)
5. `engine.ts` / `deterministic.ts` (mission loop)
6. `control.ts` / `verification.ts` (guidance invariants)
7. `comms.ts` / `downlink.ts` (telemetry)
8. `fault.ts` (verification)
9. `timeline.ts` (I/O, leaf — last because file format can be fixed)

This order is the **Automatic Port Queue** — foundational before mission logic.

## Element Registry Excerpt (full in 03_CONTRACT_REGISTRY)

```
ELEMENT_ID           SOURCE_FILE                CATEGORY       FORTRAN_REQ
CONST_TIMING         isa.ts:TIMING_MCT          COMPUTATION    YES
MEM_ERASABLE         memory.ts:ERASABLE_MAP     STATE          YES
CPU_STEP             cpu.ts:AgcCpu.step         COMPUTATION    YES
EXEC_NOVAC           executive.ts:novac         CONTROL_FLOW   YES
ORBOT_CONIC          orbital.ts:conicPropagate  COMPUTATION    YES
PROP_THROTTLE        propulsion.ts:throttleCmd  COMPUTATION    YES
STATE_CANON          state.ts:State             STATE          YES
REPLAY_STEP          deterministic.ts:step      CONTROL_FLOW   YES
...
PRESENTATION_DSKY    dsky.ts:dispatchVerb       PRESENTATION   NO
GLUE_MAP             memory.ts:Map              RUNTIME_GLUE   NO
```
