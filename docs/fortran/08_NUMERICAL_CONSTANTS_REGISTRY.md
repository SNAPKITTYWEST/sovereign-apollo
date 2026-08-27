# Numerical Constants Registry

> Preserves TS → mathematical → FORTRAN mapping per Phase 6. DO NOT change approximations without spec authorization.

| Symbol | TS Source | Value | Units | FORTRAN Name | Evidence / Fidelity |
|--------|-----------|-------|-------|--------------|---------------------|
| `MCT_US` | `isa.ts:27` | 11.7 | µs | `MCTUS` REAL*8 | DOCUMENTED R-393 |
| `TIMING_MCT` TC/CCS/AD | `isa.ts:32` | 1,2,2… | MCT | `ITIMTC(0:7)` INTEGER | DOCUMENTED; MP 3, DV 6 |
| `ERASABLE_SIZE` `FIXED_SIZE` | `memory.ts:5` | 2048, 36864 | words | `NERAS=2048, NFIXED=36864` PARAMETER | DOCUMENTED (2K rope 36×1K) |
| `MU_MOON` | `orbital.ts:7` | 4.9028e12 | m³/s² | `XMU_MOON 4.9028D12` | DOCUMENTED FIXED_FIXED_CONSTANT_POOL |
| `MU_EARTH` | `orbital.ts:7` | 3.986004418e14 | m³/s² | `XMU_EART` | DOCUMENTED |
| `R_MOON` | `orbital.ts:8` | 1 737 400 | m | `RMOON` | DOCUMENTED |
| `R_EARTH` | `orbital.ts:8` | 6 371 000 | m | `REARTH` | DOCUMENTED |
| `ENGINES.DPS` thrust | `propulsion.ts:5` | 45 000 | N | `THRMAX(1)=45000.D0` | DOCUMENTED DPS max |
| `DPS isp` | `propulsion.ts:5` | 311 | s | `ISPDPS=311.D0` | DOCUMENTED |
| `DPS throttleMin/Max` | `propulsion.ts:5` | 0.10 / 0.94 | fraction | `THRMIN/THRMAX` | DOCUMENTED 10-57%→94% |
| `ENGINES.APS` 15.5kN | `propulsion.ts:5` | 15 500 | N | `THRMAX(2)` | DOCUMENTED APS |
| `ENGINES.SPS` 91.19kN | `propulsion.ts:5` | 91 190 | N | `THRMAX(3)` | DOCUMENTED SPS 20.5 klbf |
| `F-1` 6.77MN | `saturnV.ts:4` | 6.77e6 | N | `THRMAX(4)` | DOCUMENTED S-IC |
| `J-2` 1.033MN | `saturnV.ts:4` | 1.033e6 | N | `THRMAX(5)` | DOCUMENTED S-II/S-IVB |
| `SATURN_V` prop kg | `saturnV.ts:5` | 2 039 000,480 000,119 000 | kg | `PROPKG` | DOCUMENTED |
| `CSM_SPEC` cmMass 5800 | `csm.ts:4` | 5 800 | kg | `MCM=5800.D0` | DOCUMENTED AOH |
| `LM_SPEC` total 15100 | `lm.ts:4` | 15 100 | kg | `MLM=15100.D0` | DOCUMENTED |
| `DEADBAND` 0.3° | `control.ts:7` | 0.3 | deg | `DBAND=0.3D0` | DOCUMENTED DAP |
| `RATE_DB` 0.3°/s | `control.ts:7` | 0.3 | deg/s | `RDBAND` | DOCUMENTED |
| `GIMBAL lock 85°` | `control.ts:10` | 85 | deg | `GLOCK=85.D0` | DOCUMENTED 364 |
| `g` (Lunar placeholder used in engine stub) | `engine.ts:23` | 1.62 | m/s² | `GMOON=1.62D0` | INFERRED stub (documented lunar =1.62; engine scales *0.1 — preserved verbatim as APPROXIMATION) |
| `9.80665` g0 | `propulsion.ts:11` | 9.80665 | m/s² | `G0` | DOCUMENTED standard |
| SHA256 replaced checksum mod | `replay.f:ICHFNC` | 1 000 000 007 | — | `IMOD=1000000007` | MODERN CONVENIENCE → APPROXIMATION (deterministic, period-plausible CRC) |

## Transformation Example (Phase 6)

```
TypeScript expression                        Mathematical expression               FORTRAN implementation
throttle = |aCmd|/fcEff clamped [0.10,0.94]  t = min(max(|a|/f,0.10),0.94)         THROTC = DMIN1(DMAX1(DABS(ACMD)/FCEFF,0.1D0),0.94D0)
mass -= thrust/(Isp*9.80665)*dt               m' = m - (T/(Isp·g0))·Δt             AMASS = AMASS - THRUST/(ISP*G0)*DT
pos += vel*dt (Euler)                        r' = r + v·Δt (explicit Euler)       POS(I)=POS(I)+VEL(I)*DT   loop I=1,3
|v| = hypot(v)                               |v| = sqrt(Σ v_i²)                    VMAG = DSQRT(V(1)**2+V(2)**2+V(3)**2)
```

All above **preserve original TS approximations** (Euler stub, 0.1*g scaling) — not "improved" to RK4.

## FORTRAN Storage

All in `BLOCK DATA` per file, e.g. `propulsion.f`:

```fortran
      BLOCK DATA ENGDTA
      COMMON /ENGTAB/ THRMAX(5), ISPV(5), THRMIN(5), THRMAXF(5)
      REAL*8 THRMAX, ISPV, THRMIN, THRMAXF
      DATA THRMAX/45000.D0,15500.D0,91190.D0,6.77D6,1.033D6/
      DATA ISPV/311.D0,311.D0,314.D0,263.D0,421.D0/
      DATA THRMIN/0.10D0,1.D0,1.D0,1.D0,1.D0/
      DATA THRMAXF/0.94D0,1.D0,1.D0,1.D0,1.D0/
      END
```
