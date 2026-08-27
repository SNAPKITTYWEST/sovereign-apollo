# Deterministic Mission Loop — Explicit FORTRAN Control Flow

> Replaces TS hidden event glue with `MISSION LOOP` per Phase 5.

## Loop Invariant

```
INITIAL STATE (from BLOCK DATA + timeline file)
+ INPUT EVENTS (IVERB/INOUN, fault flags)
+ CONSTANTS (08 registry)
+ TIMESTEP (DT = 0.001 s minor, 2.0 s Servicer)
= RESULTING STATE (deterministic)
```

No `Date.now()`, no `Math.random()`, no GC, no async.

## Pseudocode (actual code in `fortran1978/main.f`)

```fortran
      PROGRAM SOVAPOL
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER IMETSC, IMETH(3), IVEH, IGUID, IENG, IENGON, ICOMM
      INTEGER IALARM, IPHASE(8), NEVENT, CURSOR, IERR, IVERB, INOUN
      REAL*8 POS(3), VEL(3), AMASS, AMDRY, CDU(3), THRUST, ISP, THROTT
      CHARACTER*8 CMET
      COMMON /MSTATE/ IMETSC, IMETH, IVEH, IGUID, IENG, THRUST,
     *                ISP, THROTT, IENGON, ICOMM, POS, VEL,
     *                AMASS, AMDRY, CDU, IALARM, IPHASE
      COMMON /MSTATC/ CMET

C     --- INIT (replaces TS constructor + BLOCK DATA) ---
      CALL BLKINI
      CALL LDTIML('mission_timeline.txt', NEVENT, IERR)
      IF (IERR.NE.0) STOP 'LDTIML failed'
      CALL REPINI
      CURSOR = 0
      OPEN(UNIT=11, FILE='replay_out.txt', STATUS='UNKNOWN')

C     --- MISSION LOOP (replaces DeterministicReplay.step callbacks) ---
 10   CONTINUE
C       READ INPUT (replaces Dsky.key callback / event)
        CALL RDINPT(IVERB, INOUN, IERR)

C       UPDATE GUIDANCE (throttle + DAP) — replaces Servicer 2-s tick hidden in engine.ts
        CALL UPDGUID(IERR)

C       UPDATE NAVIGATION (conic/Encke stub)
        CALL UPDNAV(IERR)

C       UPDATE VEHICLE (physics tick, mass flow, pos/vel)
        CALL ENGSTP(0.001D0, IERR)   ! DT=1ms minor; internal accum to 2s Servicer

C       UPDATE TELEMETRY (build frame, comms SM, checksum)
        CALL BFRAME(IMETSC, IGUID, NWORDS, IERR)
        CALL COMUPD(1, -80.D0, ICOMM, IERR)

C       WRITE STATE (fixed-format, replaces JSON stringify + SHA)
        CALL WRSTATE(11, IERR)

C       VERIFY INVARIANTS (replaces assertInvariant throw)
        CALL ASSINV(IERR)
        IF (IERR.NE.0) IALARM = 1202

C       NEXT TICK (replaces callback scheduling)
        CURSOR = CURSOR + 1
        IF (CURSOR .LT. NEVENT) GOTO 10

      CALL WRSUMM(11)
      CLOSE(11)
      STOP
      END
```

## Mapping to TS Glue

| TS Hidden Flow | FORTRAN Explicit | File |
|----------------|------------------|------|
| `new DeterministicReplay().replayAll()` loop | `GOTO 10` mission loop `main.f` | `replay.f: REPSTP` inlined |
| `Dsky.key()` callback → `dispatchVerb` | `RDINPT` READ(5,*) IVERB | `dsky.f` |
| `PhysicsEngine.servicerAccum >=2000 → servicerTick` | `COMMON /PHYSCF/ ISRVAC` accum in `ENGSTP` — `IF (ISRVAC.GE.2000) CALL SVCTCK` | `engine.f` |
| `Executive.tick()` Waitlist scan | `CALL EXECTK(1)` per minor tick | `executive.f` |
| `buildFrame() → SHA256` hash chain | `CALL BFRAME` → `ICHFNC` checksum chain `COMMON /REPLAY/` | `telemetry.f`, `replay.f` |
| `throw ExecOverflowError(1202)` | `NOVAC` returns `ISTAT=1202` → `IALARM=1202` → `ASSINV` flags | `executive.f` |
| `MsfNetwork.route()` | `CALL COMUPD` + `WRITE(11,...)` | `comms.f` |
| `JSON canonical + SHA` | `WRITE` FORMAT + `ICHKSUM = MOD(prev*31+IMETSC, IMOD)` | `replay.f` |

## Replay Format Integration

Each `WRSTATE` writes one 80-col record per `04_CANONICAL_STATE_SPEC` plus checksum trailer:

```
000:00:00       0   0   0   0.000 ...  CHK=...
```

See `11_REPLAY_FORMAT.md`.

## Determinism Proof

- Fixed `DT`, no `RANDOM`, static `COMMON`, same file input → same `replay_out.txt` byte-for-byte across `gfortran` runs on same platform (verified in `13_DIVERGENCE_REPORT`).
