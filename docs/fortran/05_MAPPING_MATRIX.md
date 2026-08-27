# TypeScript → FORTRAN 77 Mapping Matrix

> Every translation documents **SEMANTICALLY EQUIVALENT** vs **APPROXIMATION** per Phase 4.

| TypeScript | FORTRAN Target | File / Symbol | Equivalence | Rationale |
|------------|----------------|---------------|-------------|-----------|
| `number` (15-bit oct word) | `INTEGER` (0..32767, masked `IAND(077777)`) | `agc_memory.f: I15ADD` | **EQUIVALENT** | AGC words fit in 16-bit signed; parity stripped — 1's complement end-around preserved |
| `number` (real, meters, m/s, kg, N) | `REAL*8` / `DOUBLE PRECISION` | `m_state.f: POS/VEL/AMASS` | **EQUIVALENT** | TS `number` is IEEE 64 — FORTRAN `REAL*8` same 53-bit mantissa |
| `boolean` | `INTEGER` 0/1 flag | `m_state.f: IENGON` | **EQUIVALENT** | `true→1, false→0` |
| `object` State | `COMMON /MSTATE/` | `m_state.f` | **EQUIVALENT** | Flat struct → COMMON-backed aggregate |
| `array` `Vec3` `[x,y,z]` | `REAL*8 POS(3)` `VEL(3)` `CDU(3)` | `m_state.f` | **EQUIVALENT** | Contiguous column-major; ordering preserved [0]=X |
| `function` pure (e.g., `throttleCommand`) | `REAL FUNCTION THROTC` | `propulsion.f` | **EQUIVALENT** | Same formula `|ACMD|/FCEFF` clamped |
| `function` mutating `step()` | `SUBROUTINE ENGSTP/AGCSTEP` with `COMMON` | `engine.f` `agc_cpu.f` | **EQUIVALENT** | Side effects via COMMON, return `IERR` not throw |
| `module` ES import | Source-file compilation unit `+ INCLUDE` or `COMMON` | `agc_*.f` | **EQUIVALENT** | Manual link `gfortran *.f` |
| `enum` `GuidanceMode` `"P63"` | `INTEGER` constants `P_P63=63` | `m_state.f: PARAMETER (P_P63=63)` | **EQUIVALENT** | Integer flag table |
| `enum` `VehicleState` | `INTEGER IVEH` 0..10 | `m_state.f` | **EQUIVALENT** | |
| `class` state (`AgcMemory`, `Executive`) | `COMMON` state block + `SUBROUTINE` ops | `agc_memory.f: COMMON /AGCMEM/` `EXECUTIVE.f: COMMON /EXEC/` | **EQUIVALENT** | Class instance → single COMMON instance (static) |
| `class` multiple instances | `ARRAY` of COMMON entries or passed arrays | Not needed (single AGC/Executive) | **APPROXIMATION** | TS allowed multiple `DeterministicReplay`; FORTRAN uses one global — sufficient for mission loop |
| `callback` / `event` | Explicit poll + flag in `MISSION LOOP` | `main.f: MISSION LOOP` (Phase 5) | **EQUIVALENT** (by design) | Converts hidden control flow to explicit sequence |
| `Promise` / `async` | Sequential `CALL` | — | **EQUIVALENT** | No async in source; CLI is sync |
| `throw` `ExecOverflowError(1202)` | `INTEGER ISTAT=1202` return code | `executive.f: NOVAC` | **EQUIVALENT** | Exception → status code |
| `throw` `InvariantViolation` | `INTEGER IERR=1..2` | `verification.f: ASSINV` | **EQUIVALENT** | |
| `JSON` timeline | Fixed-format file `READ(10,100)` `FORMAT(A8,I8, ...)` | `timeline.f: LDTIML` | **APPROXIMATION** (truncated display vs full double) | File record truncated per `04_CANONICAL_STATE_SPEC`; differential tests compare `COMMON` not file text |
| `JSON` canonical `stringify` | `WRITE(11,200) CMET,IMETSC,...` | `replay.f` | **APPROXIMATION** | Same fields, different formatting; hash replaces with checksum (see next) |
| `Map` erasable `channels`, `phaseTable` | Indexed arrays `ICHAN(0:77)`, `IPHASE(8)` | `agc_memory.f` `executive.f` | **EQUIVALENT** | `Map.get(k)` → `ICHAN(k)` |
| `crypto SHA256` | `INTEGER ICHKSUM = MOD(prev*31 + IMETSC + INT(AMASS), 1000000007)` | `replay.f: ICHFNC` | **APPROXIMATION** (intentional) | Modern crypto removed — period crypto not 1978; 32-bit checksum preserves determinism & diff detection without runtime |
| `structuredClone` | `DO I=1,3 POSOUT(I)=POS(I)` loop | `engine.f` | **EQUIVALENT** | Explicit copy |
| UI event `Dsky.key()` | Integer `IVERB,INOUN` read from `READ(5,*)` / `COMMON /DSKY/` | `dsky.f` | **APPROXIMATION** (presentation dropped) | Keep verb/noun as command input, drop EL rendering |
| `Math.hypot` `|v|` | `DSQRT(x*x+y*y+z*z)` | `interpreter.f` | **EQUIVALENT** | Same double math |
| `toFixed(2)` canonical | `FORMAT(F8.2)` | `replay.f` | **EQUIVALENT** | Same rounding |
| `Date.now()` / `Math.random` | None (not used) | — | — | Engine is fixed-dt deterministic per archaeology |
| Dynamic `import()` / `require` | `INCLUDE` / link-time `gfortran` | — | **EQUIVALENT** | |

## Eliminated Modern Runtime Features

- **Objects/closures/promises** → explicit COMMON + CALL
- **Generics** → `REAL*8`/`INTEGER` explicit
- **`Map`/`Set`** → arrays
- **Garbage collection** → static `COMMON` + `BLOCK DATA` init
- **Web APIs / JSON / Fetch** → `OPEN/READ/WRITE` file I/O
- **npm / dynamic loader** → `gfortran` + `make` (see `15_BUILD_INSTRUCTIONS`)

## Numerical Fidelity Notes

- Original DP 28-bit 1's complement vector scale (INFERRED per `interpreter.ts:5`) preserved as `DOUBLE` — labeled **APPROXIMATION** in `interpreter.f` header; difference <1e-6 relative, within differential tolerance `1e-9` for invariants, `1e-6` for pos/vel.
- Euler placeholder in `engine.ts:15` preserved verbatim in `engine.f` Euler — **not improved** to RK4 unless spec authorizes (historical fidelity).
- All trig `DSIN/DCOS/DATAN2` vs TS `Math.*` — **EQUIVALENT** (same double lib).
