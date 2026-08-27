# Historical Fidelity Report — 1978 FORTRAN Port

> Separates **HISTORICAL APOLLO**, **MODERN RECONSTRUCTION**, **1978 PORT** per Phase 10. Never claims new FORTRAN was NASA flight code.

## Categories

### HISTORICAL APOLLO (DOCUMENTED)

- AGC Block II instruction set, 1's complement, MCT 11.7µs, erasable 2K / fixed 36K, channels, Executive/Waitlist/Phase Table, Interpreter VM, DSKY verbs, Servicer 2-s, LEM geometry, Saturn V performance — all from Luminary099 + R-393 + Saturn V Manual + AOH. Evidence IDs LUM099-001, AGC-DOC-001, SATURNV-001.
- Mission timeline 22 events from NASA Mission Report / Flight Plan (RECONSTRUCTED but grounded in documented dates).
- Throttle law 0.10–0.94, deadbands 0.3°, gimbal 85°, MU/R constants — from FIXED_FIXED_CONSTANT_POOL.

### MODERN RECONSTRUCTION (TypeScript)

- Deterministic replay hash chain SHA256, JSON timeline, physics Euler stub with `g*0.1`, conic stub `r+v*dt`, Node `fs`/`crypto`/`Map`, `DeterministicReplay` class, `LocalMissionControl` web stub — all **MODERN DESIGN** per evidence registry.
- These are not historical but are the **reference** for the port.

### 1978 PORT (This Project)

- Conservative FORTRAN 77 fixed-form, `COMMON`/`BLOCK DATA`/`SUBROUTINE`/`FUNCTION`/`CALL`, static arrays, `INTEGER` flags for booleans/enums, `REAL*8` for doubles, `CHARACTER*9` for MET, `OPEN`/`READ`/`WRITE` file I/O, `GOTO` mission loop, `PARAMETER` constants, no `MODULE`/`ALLOCATABLE`/`DERIVED TYPE`/`IMPLICIT NONE`/`CONTAINS`.
- Target compiler: `gfortran -std=legacy` (modern) emulating late-1970s `f77` (e.g., CDC 6000, IBM 370). Avoids post-1978 features.

## Fidelity Claims — What Survived Unchanged

| Semantics | TS → FORTRAN | Verdict |
|-----------|--------------|---------|
| 1's complement add | `I15ADD` same end-around carry | **Equivalent** |
| Opcode/Channel tables | `TIMING_MCT`, `CHANNELS` literal values preserved | Equivalent |
| Executive overflow 1202 | `NOVAC` threshold 8 jobs → `ISTAT=1202` | Equivalent |
| Waitlist T5 queue | `LONGCL`/`EXECTK` insertion sort by time | Equivalent |
| Vector UNIT/DOT/VXM | `DSQRT`/`DOTF` same formulas | Equivalent |
| Throttle law `|a|/F` clamp | `THROTC` same | Equivalent |
| DAP deadbands 0.3° | `DBAND` same | Equivalent |
| Mission sequencing P63→P64→P66 | `IGUID` flags 63,64,66 | Equivalent |
| Timeline 22 events MET order | `mission_timeline.txt` same | Equivalent |
| Fault 1202 at 102:38:22 | `FLTINS(0, ...)` → `IALARM=1202` | Equivalent |

## What Required Approximation

| TS | FORTRAN | Reason | Class |
|----|---------|--------|-------|
| `SHA256` hash chain | `MOD(prev*31+IMETSC+AMASS, 1e9+7)` checksum | 1978 no crypto runtime; preserves determinism & diff detection, not crypto strength | **APPROXIMATION** |
| `JSON` timeline | Fixed-format `A9 1X I8 ...` file | 1978 no JSON parser; preserves fields, different formatting | APPROXIMATION |
| `Map` for channels/phase | `ICHAN(0:77)`, `IPHASE(8)` arrays | No Map in 77 | APPROXIMATION (functionally equivalent) |
| `throw` exceptions | `IERR/ISTAT` integer codes | No exceptions in 77 | APPROXIMATION |
| `number` 64-bit float for DP | `REAL*8` (64-bit) | Equivalent precision; original DP 28-bit 1's complement scale INFERRED → APPROXIMATION labeled |
| Euler stub `pos+=vel*dt` | Same Euler loop `POS(I)=POS(I)+VEL(I)*DT` | Preserves TS approximation, not flight RN | APPROXIMATION (intentional) |
| `g*0.1` lunar stub | `GMOON*0.1` same | Preserves TS placeholder, not physical | APPROXIMATION |
| `Dsky` display strings | `IVERB/INOUN` integer input via `READ(5,*)` | Presentation dropped, command kept | APPROXIMATION |

## What Was Eliminated (Modern Runtime Features)

- Objects/classes → `COMMON` + `SUBROUTINE`
- Closures/callbacks/promises → explicit `GOTO` loop
- `Map`/`Set` → arrays
- `JSON`/`Fetch`/`crypto` → file I/O + checksum
- `npm`/`vite`/`tsx` → `gfortran` + `make`
- `structuredClone` → `DO` copy loops
- Browser DOM / Web APIs → `WRITE` to line printer

## What TS Computed vs Displayed vs Glue State

- **Computed (ported):** ISA decode, memory add, CPU step, interpreter vectors, Executive scheduling, orbital stub, throttle, DAP, state canonical, telemetry word build, mission loop, fault flags, invariants.
- **Displayed (not ported):** DSKY `R1/R2/R3` strings, `LocalMissionControl` web dashboard, `replay` pretty JSON.
- **Glue state introduced (eliminated):** `Map` phaseTable, `Promise` wrappers, `JSON` canonical string order, `SHA256` hex. Replaced with `COMMON` arrays, `GOTO`, `FORMAT`, `MOD` checksum.

## Verification of Historical Separation

Every FORTRAN routine header cites TS contract and evidence ID, e.g.:

```fortran
C     THROTC — DOCUMENTED THROTTLE_CONTROL 793-797
C     Maps to src/physics/propulsion.ts:throttleCommand
```

No file claims to be original Apollo flight code. The `fortran1978/` directory is labeled **1978 PORT** — a reconstruction in the language of the era.

## Review Gate

- Can reviewer trace every FORTRAN routine to a TS contract? **Yes** — see 03 registry + 06 architecture.
- Was any uncertain inference converted to fact? **No** — INFERRED gaps (e.g., Euler scale) remain labeled APPROXIMATION.
