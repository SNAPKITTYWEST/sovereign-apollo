# Canonical Mission State Specification — Language-Independent

> This spec is the **contract** between TypeScript UI and FORTRAN simulator. Both consume/produce this state. See `src/mission/state.ts:1` (TS) and `fortran1978/m_state.f` (FORTRAN).

## State Vector (conceptual, from Phase 7)

```
MISSION_TIME        INTEGER seconds from liftoff (MET) + CHARACTER*8 "HHH:MM:SS"
MISSION_PHASE       INTEGER flag  (see PHASE table)
VEHICLE_POSITION    REAL*8(3) meters  ECI (Earth) or LCL (Moon) — frame per PHASE (documented in UFRAMES)
VEHICLE_VELOCITY    REAL*8(3) m/s
VEHICLE_ATTITUDE    REAL*8(3) degrees CDU (outer/middle/inner) + REAL*8(3) deg/s rate
PROPULSION_STATE    engine flag + thrust N + Isp s + throttle + engOn flag
GUIDANCE_MODE       INTEGER flag  (P00=0, P12=..., P63=63, etc.)
NAVIGATION_STATE    state vector + covariance placeholder (not yet ported full W-matrix — fidelity report)
TELEMETRY_STATE     listId + word count + sync
COMMUNICATION_STATE INTEGER flag  ACQUIRE=0, LOCK=1, DATA=2, DROP=3
FAULT_STATE         INTEGER code  0=none, 1201/1202, 99=COM DROP, etc.
MASS                REAL*8 kg total + dry
```

## TS ↔ FORTRAN Binding

| Conceptual Field | TS `State` (`state.ts:6`) | FORTRAN `COMMON /MSTATE/` (`m_state.f`) | Units | Notes |
|----------------|---------------------------|------------------------------------------|-------|-------|
| MET seconds | `metSeconds:number` | `IMETSC` INTEGER | s | canonical |
| MET string | `met:string "000:00:00"` | `IMETH(3)` INTEGER H,M,S + `CMET*8` CHAR | — | TS presentation only; FORTRAN stores H/M/S |
| vehicle | `vehicle: VehicleState` string enum | `IVEH` INTEGER (0 stack…10 reentry) | — | map table `docs/fortran/05_MAPPING_MATRIX.md` |
| guidanceMode | `guidanceMode: GuidanceMode` | `IGUID` INTEGER (0 IU, 63 P63…) | — | see PHASE table |
| propulsion.engine | `propulsion.engine:string` | `IENG` INTEGER (1 DPS,2 APS,3 SPS…) | — | `ENGINES` table |
| propulsion.thrustN | `propulsion.thrustN:number` | `THRUST` REAL*8 | N |  |
| ispS | `propulsion.ispS:number` | `ISP` REAL*8 | s |  |
| throttle | `propulsion.throttle:number` | `THROTT` REAL*8 | 0..1 | clamp 0.10-0.94 DOCUMENTED |
| engOn | `propulsion.engOn:boolean` | `IENGON` INTEGER 0/1 | — | `boolean→INTEGER 0/1` |
| comms | `comms:CommsState` | `ICOMM` INTEGER | — | MSFN/LOS/VHF mapped |
| position | `position:[num,num,num]` m | `POS(3)` REAL*8 | m | SI |
| velocity | `velocity:[num,num,num]` | `VEL(3)` REAL*8 | m/s | SI |
| mass | `massKg:number` | `AMASS` REAL*8 | kg |  |
| dryMass | `dryMassKg:number` | `AMDRY` REAL*8 | kg |  |
| cdu | `cdu:[num,num,num]` deg | `CDU(3)` REAL*8 | deg | outer/mid/inner |
| alarm | `alarm?:string` | `IALARM` INTEGER code | — | 0 none, 1202 etc. |
| phaseTable | `phaseTable?:number` | `IPHASE(8)` INTEGER per job | — | Executive Phase Table (DOCUMENTED) |

## FORTRAN COMMON Layout (`fortran1978/m_state.f`)

```fortran
      COMMON /MSTATE/ IMETSC, IMETH(3), IVEH, IGUID, IENG, THRUST,
     *                ISP, THROTT, IENGON, ICOMM, POS(3), VEL(3),
     *                AMASS, AMDRY, CDU(3), IALARM, IPHASE(8)
      INTEGER IMETSC, IMETH, IVEH, IGUID, IENG, IENGON, ICOMM
      INTEGER IALARM, IPHASE
      REAL*8 POS, VEL, AMASS, AMDRY, CDU, THRUST, ISP, THROTT
      CHARACTER*8 CMET
      COMMON /MSTATC/ CMET
```

## Invariants (from `src/sovereign/verification.ts:5`)

- `THROTT ∈ [0.10,0.94]` if `IGUID = 63 or 64`
- `AMASS ≥ AMDRY`
- `IVEH`/`IGUID` sequence monotonic per timeline (P63→P64→P66)

TS throws `InvariantViolation`; FORTRAN sets `IERR=1..2` in `ASSINV`.

## Serialization — Canonical File Record (replaces JSON)

**FORTRAN fixed-format record (80 columns, card image compatible):**

```
 Columns  Format  Field
   1-8    A8      CMET  "HHH:MM:SS"
   9-16   I8      IMETSC
  17-20   I4      IVEH
  21-24   I4      IGUID
  25-32   F8.2    THROTT*1000 (permille)
  33-40   I8      IALARM
  41-60   3F7.1   POS(1..3) /1000 (km, 1 dec)
  61-78   3F6.1   VEL(1..3) (m/s)
  79-80   I2      ICOMM
```

Full double precision kept in `COMMON`; file record is truncated for 1978 line-printer compatibility. Differential tests compare `COMMON` values with tolerance, not file truncation.

## Traceability

- Every FORTRAN routine `CALL`/`COMMON` field maps to one TS field above → see `docs/fortran/03_CONTRACT_REGISTRY.md` contracts.
- UI presents `CMET` + `IVEH` textual; FORTRAN computes `POS/VEL/THRUST`; both agree on canonical state — verified by `tests_fortran/diff_test.ts`.
