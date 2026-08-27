# Replay Format — Deterministic, File-Based (No Browser, No JSON)

> Generated without browser; consumed by both TS reference and FORTRAN. Each step reproducible from initial state + inputs + constants + timestep per Phase 8.

## Formula

```
INITIAL STATE (BLOCK DATA + timeline file)
+ INPUT EVENTS (IVERB/INOUN per tick, fault flags)
+ CONSTANTS (08 registry)
+ TIMESTEP (DT)
= RESULTING STATE (replay_out.txt record N)
```

## TypeScript Reference Output (existing)

- `data/mission_timeline.json` — 22 events, source for FORTRAN input
- `replay_*.jsonl` (hash-chained) — TS `DeterministicReplay` writes `{met, vehicle, mode, pos, vel, hash}` per `src/replay/deterministic.ts:26`
- `data/mission_timeline.csv` — CSV mirror via `scripts/gen-csv.ts`

## FORTRAN Canonical Replay File (`replay_out.txt`)

**One fixed-format 80-col record per mission event (22 lines) + checksum trailer.**

```
 Columns  Format  Field (FORTRAN)          Example     TS Equivalent
   1-8    A8      CMET                     000:00:00   state.met
   9-16   I8      IMETSC                   0          state.metSeconds
  17-20   I4      IVEH (0..10)             0          state.vehicle flag
  21-24   I4      IGUID (0,63,64...)       0          state.guidanceMode flag
  25-32   F8.2    THROTT*1000 permille     0.00       propulsion.throttle
  33-40   I8      IALARM (0,1201,1202)     0          state.alarm code
  41-60   3F6.1+? Actually 3F7.1 km        0.0 0.0 0.0  position (km display)
  61-78   3F6.1   VEL m/s                  0.0 etc.   velocity
  79-80   I2      ICOMM (0-3)              0          comms state
```

Full `REAL*8` values stay in `COMMON /MSTATE/`; file record is **display-truncated** for 1978 line-printer (80 columns). Differential tests compare `COMMON` memory with tolerance, not file truncation — file is human-readable summary.

**Trailer (line 23):**

```
CHK= 1234567890  N=22  FINAL POS 0.0 0.0 0.0
```

Where `CHK` is iterative checksum `ICHKSUM = MOD(ICHKSUM*31 + IMETSC + INT(AMASS), 1000000007)` per `replay.f:ICHFNC` (period-plausible CRC replacing TS SHA256 per `05_MAPPING_MATRIX`).

## Generation — No Browser

```bash
# TS side (reference)
npm run replay:mission > ts_replay.jsonl
npx tsx scripts/gen-fortran-timeline.ts   # JSON → mission_timeline.txt (fixed format)

# FORTRAN side (no browser)
gfortran -o sovapol fortran1978/*.f   # or make
./sovapol < dsky_commands.txt > replay_out.txt   # reads mission_timeline.txt, writes replay_out.txt
```

Both start from same `INITIAL STATE` (`data/mission_timeline.json` → `mission_timeline.txt`).

## Test Vector Template

```
INPUT  (timeline record N: MET, IVEH, IGUID)
  → TypeScript ref: replay.step().state (TS)
  → FORTRAN: COMMON /MSTATE/ after UPDGUID/ENGSTP/BFRAME (FORTRAN)
  → COMPARE with tolerances (see 12)
```

## Properties

- **Reproducible:** same input file + constants → same output bytes (no clock, no random)
- **Independent:** TypeScript UI and FORTRAN both map to same canonical state spec `04_CANONICAL_STATE_SPEC`
- **First-divergence detectable:** differential harness logs first N where `|POS_TS - POS_FORTRAN| > eps` — not just final hash.
