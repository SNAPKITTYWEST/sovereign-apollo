# FORTRAN 1978 Module Architecture

> Target: conservative FORTRAN 77 fixed-format, `COMMON`/`BLOCK DATA`/`SUBROUTINE`/`FUNCTION`/`CALL`, static memory, deterministic, file I/O. Avoids objects/generics/closures/promises/JSON/Web APIs.

## Compilation Units (one file ≈ one TS module)

| FORTRAN File (`fortran1978/*.f`) | TS Source | Role | COMMON / BLOCK DATA |
|----------------------------------|-----------|------|---------------------|
| `m_state.f` | `state.ts` | Canonical state definition | `COMMON /MSTATE/` + `/MSTATC/` + `BLOCK DATA MSTDTA` — defines IMETSC, IVEH, IGUID, POS(3), VEL(3), AMASS, CDU, IALARM, IPHASE(8), CMET |
| `agc_const.f` | `isa.ts` | ISA constants, FLAGWORDS, TIMING_MCT, CHANNELS | `PARAMETER` Opcode constants; `BLOCK DATA AGCDTA` for TIMIMG |
| `agc_memory.f` | `memory.ts` | Erasable/fixed arrays, 1's complement, channels | `COMMON /AGCMEM/ IERAS(2048), IFIXED(36864), EB, FB, ICHAN(0:77)` |
| `agc_cpu.f` | `cpu.ts` | Fetch-decode-execute | `COMMON /AGCCPU/ A,L,Q,Z,BB,ICYC, IEXTND, INEXT` + uses `/AGCMEM/` |
| `agc_interp.f` | `interpreter.ts` | Vector DP VM (VLOAD/DOT/UNIT etc.) | `COMMON /IMPAC/ MPAC(7)` ; no global state otherwise |
| `executive.f` | `executive.ts` | Executive + Waitlist + Phase Table, 1202 | `COMMON /EXEC/ NJOBS, IJOBID(8), IPRIO(8), IPC(8), IVAC(8), IPHASE(8), NWAIT, IWTIME(20), IWTJOB(20)` |
| `orbital.f` | `orbital.ts` | Conic + Encke, MU, R | `PARAMETER XMU_MOON=4.9028D12 etc.` |
| `propulsion.f` | `propulsion.ts` | Engines table, throttle, massFlow | `COMMON /ENGTAB/ THRMAX(5), ISP(5), THRMIN(5), THRMAXF(5)` + `BLOCK DATA ENGDTA` |
| `control.f` | `control.ts` | DAP PD + gimbal lock | Stateless subroutines; thresholds `PARAMETER DB=0.3D0` |
| `timeline.f` | `mission/timeline.ts` | Load 22-event dataset | `COMMON /TIMELN/ NEVENT, IMETEV(22), IVEHEV(22), IGUIDV(22), ...` + file `READ` |
| `vehicle.f` | `saturnV.ts/csm.ts/lm.ts` | Stage/mass tables | `BLOCK DATA VEHDTA` with SATURN_V etc. |
| `telemetry.f` | `telemetry/downlink.ts` | Build frames, checksum | `COMMON /TELEM/ ICHKSUM, ILISTID, NWORDS` |
| `comms.f` | `telemetry/comms.ts` | Comms state machine | `COMMON /COMMS/ ISTATE(3), SIGDB(3)` |
| `engine.f` | `physics/engine.ts` | Time step + Servicer | `COMMON /PHYSCF/ DTMS, ISRVAC` + uses `/MSTATE/` |
| `replay.f` | `replay/deterministic.ts` | Mission loop, checksum chain | `COMMON /REPLAY/ CURSOR, NHASH, ICHHASH` |
| `fault.f` | `replay/fault.ts` | Fault injector | `COMMON /FAULTS/ IFTYPE` |
| `verification.f` | `sovereign/verification.ts` | Invariant checks | `SUBROUTINE ASSINV(IERR)` |
| `dsky.f` | `agc/dsky.ts` | Verb/Noun command input (presentation dropped, keep command) | `COMMON /DSKY/ IVERB, INOUN` |
| `main.f` | `mission/replay-cli.ts` + `replay/fault-cli.ts` | Deterministic mission loop program | `PROGRAM SOVAPOL` — explicit loop per Phase 5 |

## Dependency Order (link order = Automated Port Queue)

```
m_state.f → agc_const.f → agc_memory.f → agc_cpu.f → agc_interp.f → executive.f
  → orbital.f → propulsion.f → control.f → vehicle.f → timeline.f → telemetry.f → comms.f
  → verification.f → engine.f → replay.f → fault.f → dsky.f → main.f
```

Matches dependency graph `02_DEPENDENCY_GRAPH.md` (constants → vectors → memory → CPU → executive → time → orbital → propulsion → guidance → telemetry → loop → fault).

## Control Flow — Explicit Mission Loop (replaces event callbacks)

**FROM (TS event glue):**
```
EVENT → CALLBACK → STATE UPDATE → RENDER (implicit, hidden)
```

**TO (FORTRAN explicit):**
```
PROGRAM SOVAPOL
  CALL BLKINI           ! BLOCK DATA init
  CALL LDTIML(FNAME,NERR) ! READ timeline file
  CALL REPINI           ! reset hash/checksum, cursor
10 CONTINUE             ! MISSION LOOP (replaces DeterministicReplay.step)
  CALL RDINPT(IVERB,INOUN)   ! READ INPUT (DSKY verb) — replaces Dsky.key callback
  CALL UPDGUID             ! UPDATE GUIDANCE (throttleCommand, dapStep)
  CALL UPDNAV              ! UPDATE NAVIGATION (conic/encke stub) — ph 7
  CALL ENGSTP(DT,IERR)     ! UPDATE VEHICLE (physics tick)
  CALL UPDTELEM            ! UPDATE TELEMETRY (BFRAME, COMUPD)
  CALL WRSTATE             ! WRITE STATE (fixed-format file + checksum chain)
  CALL ASSINV(IERR)        ! verify invariants; if IERR≠0 set IALARM
  CURSOR = CURSOR+1
  IF (CURSOR .LT. NEVENT) GOTO 10
  CALL WRSUMM               ! final hash/checksum summary — replaces verifyDeterminism
  STOP
```

No `Map`, no `Promise`, no `JSON`, no `crypto` — all replaced per `05_MAPPING_MATRIX`.

## Memory Model

- All arrays static: `IERAS(2048)`, `IFIXED(36864)`, `IJOB(8)`, `POS(3)` — no `ALLOCATE`
- Shared via `COMMON` (not `MODULE`/`CLASS`)
- Initialization via `BLOCK DATA` (not constructor)
- `PARAMETER` for opcodes/constants (not `enum`)

## I/O Model (file-based, card-image)

- **Input:** timeline fixed-format file `mission_timeline.txt` (80-col) generated from `data/mission_timeline.json` via `scripts/gen-fortran-timeline.ts`
- **Output:** `replay_out.txt` fixed-format records per `04_CANONICAL_STATE_SPEC` + checksum trailer
- **DSKY commands:** `READ(5,*,ERR=9)` `IVERB`/`INOUN` (or batch file)
- All `OPEN(UNIT=10,FILE=...,STATUS='OLD')` — no dynamic package load.

## Historical Plausibility

- Fixed-form columns 1-5 label, 6 continuation, 7-72 statement
- `IMPLICIT DOUBLE PRECISION (A-H,O-Z)` kept explicit per file (no `IMPLICIT NONE` is 77-legal but later; we use explicit typing)
- `INTEGER` flags for booleans/enums
- `CALL` + `COMMON` only — no `CONTAINS`, no `ALLOCATABLE`, no `DERIVED TYPE`
