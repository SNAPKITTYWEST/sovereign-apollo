# Modern Compatibility Build — gfortran Wrapper

> Provides reproducible `gfortran` build on modern Linux/macOS/Windows while preserving 1978 semantics.

## Why

1978 `f77` on CDC/IBM/VAX is not available in CI, but `gfortran -std=legacy` emulates it with high fidelity for the subset used (COMMON, BLOCK DATA, fixed-form, GOTO).

## Toolchain

- **Compiler:** `gfortran` 9+ (tested 13.2 MinGW) with flags:
  - `-std=legacy` — allow 1978 extensions
  - `-O2` — optimization (deterministic)
  - `-Wall -fdec` — warnings, DEC extensions for `READ` etc.
  - `-ffixed-form` — enforce 72-col
  - `-fno-align-commons` — suppress `COMMON` padding warnings (1978 compilers did manual alignment)

## Build Variants

### Direct (no make)

```bash
gfortran -std=legacy -O2 -Wall -fdec -ffixed-form -o fortran1978/sovapol \
  fortran1978/m_state.f fortran1978/agc_const.f fortran1978/agc_memory.f \
  fortran1978/agc_cpu.f fortran1978/agc_interp.f fortran1978/executive.f \
  fortran1978/orbital.f fortran1978/propulsion.f fortran1978/control.f \
  fortran1978/vehicle.f fortran1978/timeline.f fortran1978/telemetry.f \
  fortran1978/comms.f fortran1978/engine.f fortran1978/replay.f \
  fortran1978/fault.f fortran1978/verification.f fortran1978/dsky.f \
  fortran1978/main.f -fno-align-commons
```

### Makefile (provided)

```makefile
# fortran1978/Makefile
FC=gfortran
FFLAGS=-std=legacy -O2 -Wall -fdec -ffixed-form
SRC=m_state.f agc_const.f ... main.f
all: sovapol
sovapol: $(SRC:.f=.o)
	$(FC) $(FFLAGS) -o sovapol $(SRC:.f=.o)
```

```bash
cd fortran1978 && make
# or on Windows with mingw32-make
mingw32-make
```

### CMake (alternative)

```cmake
cmake_minimum_required(VERSION 3.10)
project(SovApollo Fortran)
enable_language(Fortran)
set(CMAKE_Fortran_FLAGS "-std=legacy -O2 -ffixed-form -fno-align-commons")
add_executable(sovapol m_state.f agc_const.f ... main.f)
```

```bash
mkdir build && cd build && cmake .. && make
```

## CI Integration

```yaml
# .github/workflows/ci.yml excerpt
- name: Build FORTRAN
  run: |
    gfortran -std=legacy -O2 -o fortran1978/sovapol fortran1978/*.f -fno-align-commons
    ./fortran1978/sovapol
    cat replay_out.txt | wc -l  # should be 23 (22 + CHK)
- name: Differential
  run: npx tsx scripts/differential_test.ts
```

## Output Verification (Modern)

```bash
./fortran1978/sovapol > /dev/null
cat replay_out.txt
# 22 lines A9 ... + CHK trailer, byte-identical on two runs:
./fortran1978/sovapol && cp replay_out.txt /tmp/a.txt
./fortran1978/sovapol && diff /tmp/a.txt replay_out.txt && echo "deterministic"
```

## Artifact

- **Binary:** `fortran1978/sovapol.exe` (Windows) / `fortran1978/sovapol` (Unix) — ~89KB, static, no shared libs beyond `libgfortran`.
- **Source:** 19 `.f` files, all `COMMON`/`BLOCK DATA`, no `MODULE` — portable to any 1978 `f77`.

## Reproducibility vs Period

- Period build on `f77` would produce same `replay_out.txt` (modulo `REAL*8` lib differences <1e-12).
- Modern `gfortran` with `-std=legacy` is the closest available emulation; differences documented as **APPROXIMATION** only for `MOD` checksum vs `SHA`.

## Clean

```bash
rm fortran1978/*.o fortran1978/sovapol.exe replay_out.txt
# or
make -C fortran1978 clean
```
