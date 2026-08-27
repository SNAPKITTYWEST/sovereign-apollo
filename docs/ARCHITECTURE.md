# Vehicle Architecture Diagrams

## Stack — Launch to Lunar Surface [DOCUMENTED]

```
                    APOLLO 11 STACK  SA-507
                    ┌──────────────────────┐
                    │  CSM-107 Columbia    │  3 crew, SPS, CM/SM
                    ├──────────────────────┤
                    │  SLA                 │  Spacecraft-LM Adapter
                    │  ┌────────────────┐  │
                    │  │ LM-5 Eagle     │  │  Descent + Ascent
                    │  └────────────────┘  │
                    ├──────────────────────┤
                    │  S-IVB (J-2)         │  TLI stage, IU on top
                    ├──────────────────────┤
                    │  S-II (5× J-2)       │
                    ├──────────────────────┤
                    │  S-IC (5× F-1)       │  7.5 Mlbf
                    └──────────────────────┘
```

## CSM Breakdown

```
CSM
├── CM (Command Module)
│   ├── Pressure vessel + heat shield (Avcoat)
│   ├── 3 couches + controls + DSKY + optics
│   ├── ECS (O2, LiOH, glycol, sublimator)
│   └── 3× Main DC buses, 2× AC, 3× batteries
└── SM (Service Module)
    ├── SPS (AJ10-137, 20.5 klbf, N2O4/Aerozine)
    ├── RCS: 4 quads ×4 jets (100 lbf, MMH/N2O4)
    ├── EPS: 3 fuel cells + cryo O2/H2
    ├── ECS radiators + high-gain S-band (4 dishes)
    └── Instrument bay (SIM — not flown on 11)
```

## LM Breakdown

```
LM
├── Ascent Stage
│   ├── APS (Bell, 3500 lbf, Aerozine/N2O4, fixed)
│   ├── RCS (16×100 lbf, 2 systems)
│   ├── Pressurized cabin + DSKY + AOT + PGNS
│   ├── AGS backup + rendezvous radar (RR)
│   └── EDS + batteries
└── Descent Stage
    ├── DPS (TRW, throttle 1050–9850 lbf, gimbaled)
    ├── Landing gear (4×) + ladder + EASEP
    ├── Landing radar (LR)
    ├── Batteries + O2/H2O + PLSS recharge
    └── Engine skirt + thermal blankets
```

## Guidance Chain [DOCUMENTED]

```
IMU (gyros/accels/CDUs) ─┐
Optics (AOT/COAS) ───────┤
Landing Radar ───────────┼─→ AGC (Luminary099) → DAP → RCS/DPS/APS gimbal
Rendezvous Radar ────────┤         ↕
Ground uplink (V35/V71) ─┘      DSKY ↔ Crew
                              ↓ telemetry
                           MSFN → MCC-H
```

## Propulsion & Control Flow

```
AGC Executive → Waitlist → Servicer (2s) → FINDCDUW → DAP → TJET → RCS jets
                ↘ PHASE TABLE (restart protection)
AGC Interpreter → powered-flight subroutines → cross-product steering → ENG ON (BURN_BABY_BURN)
AGC Throttle → THROTTLE_CONTROL_ROUTINES → DPS throttle (Servicer loop)
```

## Communications Topology

```
LM S-band steerable ─┐
LM S-band omni ──────┼─→ MSFN (26m) → MCC-H (CAPCOM/ FDO/ GUIDO)
CSM S-band high-gain ─┤
VHF CSM↔LM ───────────┘
VHF LM↔EVA (PLSS) ───→ LM relay → S-band
```

## Power & ECS Simplified

```
CSM: Cryo O2/H2 → 3 Fuel Cells → 28V DC buses A/B/C → inverters → AC
LM: AgZn batteries (4) → 28V buses → ECS: glycol + sublimator + LiOH + O2
```

All diagrams are **RECONSTRUCTED** from AOH/Saturn V Manual schematics, tagged but simplified for simulation interfaces (`src/vehicle/`).
