# Phase 1 — TypeScript Architecture Map (Archaeology)

> Reverse-engineered from `sovereign-apollo/src/**/*` as of 2026-08-26. Classification per Phase 1.

## Entry Points

| Entry | File | Invocation | Class |
|-------|------|------------|-------|
| Mission Replay CLI | `src/mission/replay-cli.ts:1` | `npx tsx src/mission/replay-cli.ts [--check-hash]` | **CONTROL FLOW + I/O** |
| Fault CLI | `src/replay/fault-cli.ts:1` | `npx tsx src/replay/fault-cli.ts --fault 1202 --at 102:38:22` | **CONTROL FLOW + I/O** |
| Fetch Luminary | `scripts/fetch-luminary.ts:1` | `npm run fetch:lumi` | **I/O + RUNTIME GLUE** |
| Verify Artifacts | `scripts/verify-artifacts.ts:1` | `npm run verify:artifacts` | **I/O** |
| Gen CSV | `scripts/gen-csv.ts:1` | `npx tsx scripts/gen-csv.ts` | **I/O** |
| Tests | `tests/agc.test.ts:1`, `tests/replay.test.ts:1` | `npx vitest run` | **CONTROL FLOW** |

No browser UI entry — `src/sovereign/local-first.ts:5 LocalMissionControl.start()` is **PRESENTATION** stub, not wired to DOM.

## Modules (18 source files)

| Module | File | Exports | Category | FORTRAN Requirement |
|--------|------|---------|----------|---------------------|
| AGC ISA | `src/agc/isa.ts:1` | `Opcode`, `ExtOpcode`, `TIMING_MCT`, `CHANNELS`, `decode()`, `FLAGWORDS` | **STATE + COMPUTATION** (constants/tables) | **YES** — COMMON constants |
| AGC Memory | `src/agc/memory.ts:1` | `AgcMemory`, `ERASABLE_MAP`, `AgcMemory.add/read/write/readChannel/writeChannel` | **STATE + COMPUTATION** (1's complement) | **YES** — erasable/fixed arrays + 1's complement func |
| AGC CPU | `src/agc/cpu.ts:1` | `AgcCpu`, `CpuState`, `AgcCpu.step()` | **COMPUTATION + CONTROL FLOW** | **YES** — core fetch-decode-execute |
| AGC Interpreter | `src/agc/interpreter.ts:1` | `AgcInterpreter`, `Vec3/Mat3`, `VLOAD/VSU/VAD/DOT/UNIT/VXM/ABVAL/exec()` | **COMPUTATION** (vector DP) | **YES** — vector math |
| AGC Executive | `src/agc/executive.ts:1` | `Executive`, `RestartManager`, `Job`, `novac/endOfJob/longcall/tick/setPhase`, `ExecOverflowError` (1202) | **STATE + CONTROL FLOW** (scheduler) | **YES** — job queue + Waitlist + Phase Table |
| DSKY | `src/agc/dsky.ts:1` | `Dsky`, `DskyState`, `key/dispatchVerb` | **PRESENTATION + CONTROL FLOW** | **NO** — display only; keep flag input as INTEGER verb/noun |
| Physics Engine | `src/physics/engine.ts:1` | `PhysicsEngine`, `PhysicsConfig`, `step/runUntil` | **COMPUTATION + CONTROL FLOW** (time loop) | **YES** — main integ loop |
| Orbital | `src/physics/orbital.ts:1` | `conicPropagate`, `enckeStep`, `altitude`, `MU_*`, `R_*` | **COMPUTATION** (Kepler) | **YES** — conic/Encke |
| Propulsion | `src/physics/propulsion.ts:1` | `ENGINES`, `throttleCommand`, `massFlow` | **COMPUTATION** | **YES** — throttle law |
| Control (DAP) | `src/physics/control.ts:1` | `dapStep`, `checkGimbalLock`, constants | **COMPUTATION** | **YES** — PD + gimbal |
| Mission State | `src/mission/state.ts:1` | `State`, `GuidanceMode`, `VehicleState`, `PropulsionState`, `metToString` | **STATE** | **YES** — canonical state |
| Timeline | `src/mission/timeline.ts:1` | `loadTimeline`, `eventsToStates`, `TimelineEvent` | **I/O + STATE** (JSON ingest) | **PARTIAL** — file read → COMMON load |
| Saturn V | `src/vehicle/saturnV.ts:1` | `SATURN_V`, `stageDeltaV` | **STATE** (tables) | **YES** — tables |
| CSM | `src/vehicle/csm.ts:1` | `CSM_SPEC` | **STATE** | **YES** — tables |
| LM | `src/vehicle/lm.ts:1` | `LM_SPEC`, `LmState` | **STATE** | **YES** — tables |
| Telemetry Downlink | `src/telemetry/downlink.ts:1` | `buildFrame`, `wordsFromState`, `resetHash`, `TelemetryFrame` | **COMPUTATION + I/O** (hash chain) | **YES** — frames, but hash is MODERN CONVENIENCE (replace with simple checksum) |
| Telemetry Comms | `src/telemetry/comms.ts:1` | `CommsLink`, `MsfNetwork`, `update` state machine | **CONTROL FLOW + STATE** | **YES** — comms state machine |
| Replay Deterministic | `src/replay/deterministic.ts:1` | `DeterministicReplay`, `ReplayFrame`, `step/replayAll/canonical/verifyDeterminism` | **CONTROL FLOW + COMPUTATION** | **YES** — mission loop |
| Replay Fault | `src/replay/fault.ts:1` | `FaultInjector`, `FaultSpec`, `inject` | **CONTROL FLOW** | **YES** — fault flags |
| Sovereign Local | `src/sovereign/local-first.ts:1` | `LocalMissionControl` | **PRESENTATION + RUNTIME GLUE** | **NO** |
| Sovereign Verification | `src/sovereign/verification.ts:1` | `assertInvariant`, `InvariantViolation` | **COMPUTATION** (checks) | **YES** — invariants |
| Tests | `tests/*.ts` | — | **RUNTIME GLUE** | **NO** (but differential suite later) |

## Functions / Classes Inventory (abridged)

- **Classes with mutable state:** `AgcMemory`, `AgcCpu`, `Executive`, `AgcInterpreter`, `Dsky`, `PhysicsEngine`, `CommsLink`, `DeterministicReplay`, `FaultInjector`, `LocalMissionControl`
- **Pure functions:** `decode`, `toDP`, `conicPropagate`, `enckeStep`, `throttleCommand`, `massFlow`, `dapStep`, `checkGimbalLock`, `metToString`, `stringToMet`, `loadTimeline`, `buildFrame`, `wordsFromState`, `assertInvariant`, `stageDeltaV`
- **Interfaces/Types:** `CpuState`, `Job`, `State`, `PropulsionState`, `TimelineEvent`, `TelemetryFrame`, `StageSpec`, `PhysicsConfig`, `FaultSpec`, `DskyState`, `Vec3/Mat3`

## Event Loops / State Machines / Timers

| Mechanism | TS Implementation | Frequency | Category |
|-----------|-------------------|-----------|----------|
| Servicer 2-s guidance cycle | `PhysicsEngine.step()` accumulates `servicerAccum` → `servicerTick()` at 2000 ms `src/physics/engine.ts:25` | 0.5 Hz | **CONTROL FLOW + COMPUTATION** |
| Executive tick | `Executive.tick(dtCs)` `src/agc/executive.ts:28` scans Waitlist | 100 Hz (10 ms) nominal | **CONTROL FLOW** |
| MCT timing | `AgcCpu.state.cycles` + `TIMING_MCT` `src/agc/isa.ts:27` | 85 kHz (11.7 µs) | **COMPUTATION** (counting only) |
| Interrupt vectors | `INTERRUPT_LEAD_INS` table (not modeled as async — polled via `tick`) | — | **CONTROL FLOW** |
| Comms state | `CommsLink.update()` `src/telemetry/comms.ts:9` ACQUIRE→LOCK→DATA→DROP | per frame | **STATE MACHINE** |
| Message passing | `DeterministicReplay.step()` emits `ReplayFrame` → `buildFrame()` → `MsfNetwork.route()` | per event (22 steps) | **RUNTIME GLUE** |
| UI→Engine boundary | `Dsky.key()` → `dispatchVerb()` → `State.guidanceMode` (not exercised in CLI) | on key | **PRESENTATION** |
| Serialization | `JSON.parse/stringify` in `timeline.ts:10`, `deterministic.ts:25 canonical()`, `downlink.ts:15 SHA256` | per frame | **MODERN CONVENIENCE** |
| Configuration | `DEFAULT_CONFIG` `engine.ts:8` (`dtMs`, `servicerPeriodMs`) | init | **MODERN CONVENIENCE** |
| Error handling | `throw ExecOverflowError` `executive.ts:16`, `InvariantViolation` `verification.ts:3` | on fault | **CONTROL FLOW → status code in FORTRAN** |

## Telemetry Pipeline (Actual Data Flow)

```
loadTimeline() [timeline.ts:10 JSON read]
  → eventsToStates() [timeline.ts:16] → State[]
  → DeterministicReplay.states [deterministic.ts:14]
  → step() [deterministic.ts:35] canonical() [deterministic.ts:26] → SHA256
                                → buildFrame() [downlink.ts:10] → wordsFromState() [downlink.ts:32]
                                → MsfNetwork.route() [comms.ts:22]
  → ReplayFrame {state, telemetry, crewProc, hash} [deterministic.ts:11]
  → fault injection optionally mutates Executive/Propulsion before step [fault.ts:13]
  → verification assertInvariant() [verification.ts:5] each Servicer tick
```

## Simulation Tick Sequence (inside PhysicsEngine)

```
Engine.step(dt):
  massFlow → velocity → position (Euler, placeholder) [engine.ts:15-28]
  servicerAccum >=2000 → servicerTick()
    → guidance invariants + throttleCommand() [propulsion.ts:8] + dapStep() [control.ts:7]
```

## Classification Summary (for FORTRAN boundary)

- **COMPUTATION (port):** ISA decode, 1's complement add, CPU step, interpreter vector ops, Executive scheduling, Waitlist, orbital conic/Encke, propulsion throttle, DAP PD, state canonical hash, telemetry word build
- **STATE (port as COMMON):** AgcMemory erasable/fixed/banks/channels, CpuState, Job table, Phase Table, Vehicle State (pos/vel/mass/cdu), Timeline events, Stage specs, Telemetry frames
- **CONTROL FLOW (port explicit):** Servicer loop, Executive tick, Replay step, Comms state machine, Fault flags
- **I/O (port as file I/O):** JSON timeline load → fixed-format file read; downlink SHA256 → checksum; console.log → WRITE
- **PRESENTATION (drop):** DSKY display strings, LocalMissionControl web stub
- **RUNTIME GLUE (eliminate):** Node `fs`, `crypto`, `commander`, `vitest`, `tsx` loader, `Map`, `Promise`, `JSON`, `structuredClone`
- **MODERN CONVENIENCE (replace):** ES modules → COMMON/BLOCK DATA, dynamic allocation → static arrays, exceptions → INTEGER status

This map is the source for the Computational Contract Registry.
