# Build Instructions — 1978 FORTRAN Port

## Period-Appropriate Environment (Target)

- **Language:** FORTRAN 77 fixed-form (columns 1-5 label, 6 continuation, 7-72 statement)
- **Compiler (period):** `f77` (Unix V7), CDC FTN, IBM VS FORTRAN, Univac FTN — any 1978-conforming compiler with `COMMON`/`BLOCK DATA`/`SUBROUTINE`/`FUNCTION`.
- **Hardware (period):** PDP-11, VAX-11/780, CDC 6000, IBM 370 — 32-bit, static memory, no virtual.
- **Build (period):**

```sh
# On a 1978 system with f77
f77 -o sovapol m_state.f agc_const.f agc_memory.f agc_cpu.f agc_interp.f executive.f orbital.f propulsion.f control.f vehicle.f timeline.f telemetry.f comms.f engine.f replay.f fault.f verification.f dsky.f main.f
./sovapol < dsky_commands.txt
# Output: replay_out.txt (80-col) + line printer
```

No `npm`, no `make` required (but provided for convenience).

## Modern Compatibility Build (Provided)

For reproducibility on modern systems we provide a `gfortran` wrapper emulating 1978 semantics:

### Prerequisites

- `gfortran` 9+ (tested 13.2 MinGW) — `gfortran --version`
- `make` optional (or use `gfortran` directly)
- Node 18+ for `gen-fortran-timeline.ts` (one-time, to produce `mission_timeline.txt`)

### One-Time Setup (Generate Canonical Vectors)

```bash
cd sovereign-apollo
npm install
npx tsx scripts/gen-fortran-timeline.ts
# → fortran1978/mission_timeline.txt + mission_timeline.txt (22 events, fixed-format)
```

### Build & Run (Modern)

```bash
# Option A: gfortran directly (no make needed)
gfortran -std=legacy -O2 -Wall -fdec -ffixed-form -o fortran1978/sovapol \
  fortran1978/m_state.f fortran1978/agc_const.f fortran1978/agc_memory.f \
  fortran1978/agc_cpu.f fortran1978/agc_interp.f fortran1978/executive.f \
  fortran1978/orbital.f fortran1978/propulsion.f fortran1978/control.f \
  fortran1978/vehicle.f fortran1978/timeline.f fortran1978/telemetry.f \
  fortran1978/comms.f fortran1978/engine.f fortran1978/replay.f \
  fortran1978/fault.f fortran1978/verification.f fortran1978/dsky.f \
  fortran1978/main.f -fno-align-commons

# Option B: Makefile (if make available)
cd fortran1978 && make   # or: gmake
```

### Run

```bash
# From sovereign-apollo root (so fortran1978/mission_timeline.txt is found)
./fortran1978/sovapol.exe          # or ./fortran1978/sovapol on Unix
# With DSKY commands:
echo "37 68" | ./fortran1978/sovapol.exe

# Output:
#   replay_out.txt (80-col, 22 lines + CHK trailer)
#   stdout:  SOVEREIGN APOLLO 1978 FORTRAN SIMULATOR / NEVENT=22 / DETERMINISM OK
cat replay_out.txt
```

### Test

```bash
# Differential vs TypeScript
npx tsx scripts/differential_test.ts
# → 22/22 MATCH, 0 divergences

# Unit tests (TS)
npm test

# FORTRAN determinism (second run)
./fortran1978/sovapol.exe && grep CHK replay_out.txt
./fortran1978/sovapol.exe && grep CHK replay_out.txt  # same CHK → deterministic
```

### Reproducibility

- No network, no `Date.now()`, no random — fixed `DT` and static `COMMON`.
- Same `mission_timeline.txt` + same `gfortran -std=legacy -O2` → same `replay_out.txt` bytes on Linux/macOS/Windows (verified).

### Clean

```bash
rm -f fortran1978/*.o fortran1978/sovapol fortran1978/sovapol.exe replay_out.txt
# or
cd fortran1978 && make clean
```

## File-Based I/O (No Browser)

- **Input:** `mission_timeline.txt` (22 lines, `A9 1X I8 ...`) — generated from `data/mission_timeline.json`.
- **Output:** `replay_out.txt` (22 lines `A9 1X I8 ... 3F7.1 ...` + `CHK= ...` trailer).
- **DSKY:** `READ(5,*) IVERB, INOUN` from stdin or `dsky_commands.txt`.

## Notes for Period Systems

- If `f77` lacks `IMPLICIT DOUBLE PRECISION (A-H,O-Z)`, replace with `IMPLICIT REAL*8`.
- If `INCLUDE` not available, duplicate `COMMON` per file (already done).
- Line length 72 enforced; long `WRITE` use continuation `*` in column 6 (as in `replay.f:90`).
- `COMMON` padding warnings (`-Walign-commons`) suppressed with `-fno-align-commons` on modern `gfortran`; on 1978 compilers, reorder `COMMON` to avoid padding (move `REAL*8` before `INTEGER`).

## Modern CI

```yaml
- run: npm ci && npm run build && npm test
- run: npx tsx scripts/gen-fortran-timeline.ts
- run: gfortran -std=legacy -O2 -o fortran1978/sovapol fortran1978/*.f -fno-align-commons && ./fortran1978/sovapol
- run: npx tsx scripts/differential_test.ts
```
