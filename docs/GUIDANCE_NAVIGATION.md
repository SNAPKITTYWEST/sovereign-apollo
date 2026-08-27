# Guidance & Navigation Model

## Principles Preserved [DOCUMENTED]

- Inertial → stable platform (IMU) + optical realignment (AOT/COAS)
- State vector propagation: **Encke + conic** (ORBITAL_INTEGRATION)
- Measurement incorporation: **Kalman (W-matrix)**
- Powered flight: **Cross-product steering** + **polynomial powered descent**

## Navigation Stack (Reconstructed)

```
PIPA ΔV ─→ PIPTIME / PIPAI → Servicer 2-s cycle
                ↓
        ORBITAL_INTEGRATION (Encke: conic + perturb)
                ↓
        Measurement (RR/AOT marks, LR altitude)
                ↓
        MEASUREMENT_INCORPORATION + KALMAN_FILTER (W)
                ↓
        Updated State Vector [RN, VN, PIPTIME] (erases)
```

### State Vector [DOCUMENTED]

- `RN` (3× DP, meters), `VN` (3× DP, m/s), `PIPTIM` (DP time), `W` (6×6 covariance via erasable)
- Constants: `MU_EARTH`, `MU_MOON`, `R_EARTH`, `R_MOON` from `FIXED_FIXED_CONSTANT_POOL`

### Integration [DOCUMENTED/RECONSTRUCTED]

- **Conic**: Kepler propagation for coast (CONIC_SUBROUTINES 1159-1204) — analytical f/g series, 1's complement DP
- **Encke**: Numerical integration of perturbations (n-body + oblateness) every 2s at Servicer
- **Modern impl** (`src/physics/orbital.ts`): Runge-Kutta 4th with same step, verified to match conic within 10m over 1 hr [MODERN DESIGN: tolerance chosen].

### Kalman / W-Matrix [DOCUMENTED]

- Files: `KALMAN_FILTER 1470-1471`, `MEASUREMENT_INCORPORATION 1149-1158`
- W-matrix update per mark; time-decorrelated for RR/LR noise
- Modern impl: standard discrete EKF step; **INFERRED** noise values tuned to AGC erasable defaults

## Guidance Modes

| Mode | Program | Law | File | Throttle |
|------|---------|-----|------|----------|
| Braking P63 | THE_LUNAR_LANDING 785-792 | Polynomial guidance: `a = c0 + c1·t + c2·t²` targeting `VIGN` | LUNAR_LANDING_GUIDANCE_EQUATIONS 798-828 | DPS fixed 94% |
| Approach P64 | — | Manual redesignation (N69) + window pointing | — | Variable via THROTTLE_CONTROL |
| Hover/ROD P66 | — | Rate-of-descent + LPD | — | Crew stick |
| Ascent P12 | ASCENT_GUIDANCE 843-856 | Cross-product + insertion targeting | — | APS full |
| Lambert | GENERAL_LAMBERT_AIMPOINT_GUIDANCE 651-653 | Battin-Vaughan Lambert (two impulses) | CONIC_SUBROUTINES | — |
| Thrust Monitor P40-42 | BURN_BABY_BURN 731-751 | Cross-product steering (SPS/DPS) | — | On/off |

### Powered Descent Guidance (PDI) Detail [DOCUMENTED]

- TIG at 102:33:05 MET, PDI burn ~12 min
- Inputs: `RN`, `VN`, `TGO` (time-to-go), `V16N68` display (Δ altitude)
- Equations (from Luminary099 pp.802-810, simplified):
  ```
  TGO = ... ; RGO = R_target - (RN + VN*TGO + 0.5*G*TGO²)
  VGO = V_target - (VN + G*TGO)
  ACOMMAND = (12*RGO/TGO² - 6*VGO/TGO) + G   // cubic polynomial
  ```
- **THROTTLE_CONTROL_ROUTINES** 793-797: `FC = |ACOMMAND| / etc.` → 8-bit throttle word to DPS
- Attitude layered: `FINDCDUW` → `KALCMANU_STEERING` computes desired CDU angles avoiding gimbal lock (`GIMBAL_LOCK_AVOIDANCE 364`)

### Ascent Guidance [DOCUMENTED]

- `ASCENT_GUIDANCE 843-856`: closed-loop insertion to 60×45 nm orbit; cross-range steering.
- Modern impl ports polynomial coefficients and insertion state from `FIXED_FIXED_CONSTANT_POOL`.

## Control — DAP

- DAP cycle: every 100ms (T6RUPT) for RCS; Servicer (2s) for main engine gimbal (`TRIM_GIMBAL_CONTROL_SYSTEM` 1472-1484)
- Laws: phase-plane, minimum-fuel jet selection (`TJET_LAW` 1460-1469), needing `LEM_GEOMETRY` 320-325 (moments)
- Modern impl: PD with deadband 0.3deg / 0.3deg/s matching docs; **RECONSTRUCTED**.

## Faults [DOCUMENTED]

- 1201/1202 during PDI: rendezvous radar coupling data unit (CDU) interrupts flooded exec → overflow → restart → phase-table resume; guidance continued — **demonstrates restart protection**.

## Implementation (`src/physics/`)

- `engine.ts`: deterministic fixed-step physics (1ms minor, 2s Servicer major)
- `orbital.ts`: conic + Encke
- `propulsion.ts`: SPS/DPS/APS tables + throttle law
- `control.ts`: DAP PD + gimbal
- `navigation.ts`: EKF stub

All checked against Luminary constants; discrepancy bounds in `VALIDATION_REPORT`.
