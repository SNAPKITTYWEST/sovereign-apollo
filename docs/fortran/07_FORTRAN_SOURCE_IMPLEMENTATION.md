# FORTRAN Source Implementation — 1978 Port

> 19 compilation units, 1 program, 0 modern runtime dependencies. Each maps to a TS contract in 03.

## File List (`fortran1978/*.f`)

| File | LOC | TS Source | COMMON / Program Unit | Contract |
|------|-----|-----------|------------------------|----------|
| `m_state.f` | 55 | `state.ts` | `COMMON /MSTATE/` + `/MSTATC/` + `BLOCK DATA MSTDTA` + `IMTSEC`/`ITOMET` | 04 Canonical State |
| `agc_const.f` | 8 | `isa.ts` | `BLOCK DATA AGCDTA` `COMMON /AGCTIM/` | CONST_TIMING |
| `agc_memory.f` | 59 | `memory.ts` | `COMMON /AGCMEM/` + `BLOCK DATA AGMMEM` + `I15ADD`/`AGCRD`/`AGCWR`/`CHRD`/`CHWR` | MEM_ADD, MEM_ERAS |
| `agc_cpu.f` | 105 | `cpu.ts` | `COMMON /AGCCPU/` + `BLOCK DATA AGCPUD` + `AGCSTEP` | CPU_STEP |
| `agc_interp.f` | 75 | `interpreter.ts` | `COMMON /IMPAC/` + `BLOCK DATA INTPAD` + `DOTF`/`UNITV`/`VXMF`/`ABVALF`/`INTPRC` | INTERP_VEC |
| `executive.f` | 110 | `executive.ts` | `COMMON /EXEC/` + `BLOCK DATA EXECDT` + `NOVAC`/`ENDJOB`/`LONGCL`/`EXECTK`/`SETPHA` | EXEC_NOVAC |
| `orbital.f` | 48 | `orbital.ts` | `CONICP`/`ENCKE`/`ALTIT` + `PARAMETER XMU_*` | ORBIT_CONIC |
| `propulsion.f` | 42 | `propulsion.ts` | `COMMON /ENGTAB/` + `BLOCK DATA ENGDTA` + `THROTC`/`MASSFL` | PROP_THR |
| `control.f` | 45 | `control.ts` | `DAPSTP`/`GLOCKC` + `PARAMETER DBAND` | CTRL_DAP |
| `vehicle.f` | 36 | `saturnV.ts/csm.ts/lm.ts` | `COMMON /SATURN/`/`/CSM/`/`/LM/` + `BLOCK DATA VEHDTA` + `STAGEDV` | SATURN_TBL |
| `timeline.f` | 71 | `mission/timeline.ts` | `COMMON /TIMELN/`/`/TIMECT/` + `BLOCK DATA TIMDTA` + `LDTIML`/`EVTOST` | TIMELINE_LOAD |
| `telemetry.f` | 49 | `telemetry/downlink.ts` | `COMMON /TELEM/` + `BLOCK DATA TELDTA` + `TELINI`/`ICHFNC`/`BFRAME` | TELEM_BLD |
| `comms.f` | 35 | `telemetry/comms.ts` | `COMMON /COMMS/` + `BLOCK DATA COMDTA` + `COMUPD` | COMMS_SM |
| `engine.f` | 58 | `physics/engine.ts` | `COMMON /PHYSCF/` + `BLOCK DATA PHYDTA` + `ENGSTP`/`SVCTCK` | PhysicsEngine.step |
| `replay.f` | 112 | `replay/deterministic.ts` | `COMMON /REPLAY/` + `BLOCK DATA REPDTA` + `REPINI`/`ICHASHF`/`REPSTP`/`REPRUN`/`REPVFY`/`WRSTATE`/`WRSUMM` | REPLAY_STEP |
| `fault.f` | 34 | `replay/fault.ts` | `FLTINS` | FAULT_INJ |
| `verification.f` | 26 | `sovereign/verification.ts` | `ASSINV` | VERIF_INV |
| `dsky.f` | 38 | `agc/dsky.ts` | `COMMON /DSKY/` + `BLOCK DATA DSKYDT` + `RDINPT`/`DSPV37` | DSKY_KEY (command only) |
| `main.f` | 89 | `mission/replay-cli.ts` | `PROGRAM SOVAPOL` — explicit mission loop per 10 | Mission Loop |

**Total:** ~1100 lines, all fixed-form, `gfortran -std=legacy -O2 -Wall -fdec` **0 errors, 22 warnings (unused, truncation, padding)**.

## Build

```bash
gfortran -std=legacy -O2 -Wall -fdec -ffixed-form -o fortran1978/sovapol fortran1978/*.f -fno-align-commons
./fortran1978/sovapol.exe  # reads mission_timeline.txt, writes replay_out.txt
```

## Verification

- `test_timeline.exe` (built from `m_state.f + timeline.f + test_timeline.f`) prints 22/22 varying MET correctly.
- `npx tsx scripts/differential_test.ts` → 22/22 MATCH, 0 divergences.

## Historical Note

Every file header cites TS contract, e.g. `C     THROTC — DOCUMENTED THROTTLE_CONTROL 793-797` + `Maps to src/physics/propulsion.ts:throttleCommand`. No file claims to be NASA flight code.
