# Apollo 11 Systems Inventory

Evidence-tagged catalog of every publicly documented subsystem.

## 1. Launch Vehicle — Saturn V (SA-507) [DOCUMENTED]

| Stage | Engines | Propellant | Thrust (sea) | Burn Time | Source |
|-------|---------|------------|--------------|-----------|--------|
| **S-IC** | 5× F-1 | RP-1/LOX 2039t | 7.5 Mlbf | 168 s | SATURNV-001 |
| **S-II** | 5× J-2 | LH2/LOX 480t | 1.13 Mlbf vac | 360 s | SATURNV-001 |
| **S-IVB** | 1× J-2 | LH2/LOX 119t | 232 klbf vac | 2 burns (165s + 350s) | SATURNV-001 |
| **Instrument Unit** | — | — | Guidance, sequencing, IU computer | — | SATURNV-001 |

**Interfaces**: IU ↔ S-IVB ↔ CSM (via SLA). Separation events: S-IC/S-II @ 68 km, S-II/S-IVB @ 165 km.

**Constraints** [RECONSTRUCTED from flight manual tables]: Max Q 34 kPa @ 83s, max accel 4g.

## 2. Spacecraft

### Command/Service Module — CSM-107 Columbia [DOCUMENTED]
- **CM**: Pressure vessel, heat shield (Avcoat), 3 couches, DSKY, optics, ECS, 3× 28V DC buses
- **SM**: SPS (AJ10-137, 20.5 klbf), RCS quads (16× 100 lbf), EPS (3 fuel cells + batteries), ECS, S-band high-gain
- **Mass**: CM 5.8t, SM 6.1t, propellant 18.4t

### Lunar Module — LM-5 Eagle [DOCUMENTED]
- **Ascent Stage**: APS (3.5 klbf), RCS 16×100 lbf, AGC+PGNCS, DSKY, rendezvous radar
- **Descent Stage**: DPS (throttleable 1–10 klbf, TRW), landing gear, EASEP bay
- **Electrical**: 28V DC, 2 batteries descent, 2 ascent
- **Mass**: ~15.1t total

## 3. Guidance & Navigation [DOCUMENTED]

- **IMU**: 3-gimbal stable platform, 3 gyros, 3 accelerometers, CDU resolvers
- **Optics**: AOT (LM), sextant/scanning telescope (CSM)
- **AGC**: Block II, 2.048 MHz, 16-bit word, see `AGC_ARCHITECTURE.md`
- **PGNCS**: Primary; AGS (Abort Guidance Section) backup in LM
- **Ground**: MSFN, Carnarvon, Honeysuckle, Goldstone

## 4. AGC Software — Luminary099 [DOCUMENTED]

101 modules (see registry). Key:

| Program | File | Purpose | Guidance Mode |
|---------|------|---------|---------------|
| P00 | — | Idle | — |
| P11/P12 | P12.agc 838-842 | Powered Ascent | Ascent Guidance |
| P20-P25 | P20-P25.agc 492-614 | Rendezvous nav | — |
| P30-P37 | P30_P37.agc | Targeting | Lambert |
| P40-P47 | P40-P47.agc | Thrusting | Cross-product steering |
| P63 | THE_LUNAR_LANDING 785-792 | Braking Phase | Lunar Landing Guidance |
| P64 | LUNAR_LANDING_GUIDANCE... 798-828 | Approach | — |
| P66 | — | Manual/ROD | — |
| P70-P71 | P70-P71.agc | Insertion | — |
| Executive | EXECUTIVE.agc 1103-1116 | Multitask | — |
| Interpreter | INTERPRETER.agc 1002-1094 | VM for vector ops | — |
| Servicer | SERVICER.agc 857-897 | 2-sec guidance cycle | — |
| Waitlist | WAITLIST.agc 1117-1132 | Timed tasks | — |

## 5. Communications [DOCUMENTED]

- **S-Band** (2.1/2.2 GHz): unified voice, telemetry, ranging, TV
- **VHF** (259.7 MHz): CSM-LM, EVA
- **UHF**: Recovery beacon

## 6. Telemetry [DOCUMENTED]

- **Downlink**: 51.2 kbps PCM, lists from `DOWNLINK_LISTS.agc` pp.193-205, scheduler `DOWN_TELEMETRY_PROGRAM.agc`
- **Uplink**: Digital command via MSFN, handled by `KEYRUPT_UPRUPT.agc`

## 7. Electrical Power [DOCUMENTED/RECONSTRUCTED]

- CSM: 3× fuel cells (1.4 kW each), 3× reentry batteries
- LM: 4× AgZn batteries (400 Ah descent, 300 Ah ascent)

## 8. Environmental Control [DOCUMENTED]

- Cabin: 4.8 psi O2, glycol loop, sublimator, LiOH CO2
- Suits: PLSS (EVA), 4h O2 + cooling

## 9. Propulsion [DOCUMENTED]

- See SPS/DPS/APS/RCS sections + `BURN_BABY_BURN--MASTER_IGNITION_ROUTINE.agc`

## 10. Attitude Control [DOCUMENTED]

- DAP (Digital Autopilot): `P-AXIS_RCS_AUTOPILOT`, `Q_R-AXIS_RCS_AUTOPILOT`, `TJET_LAW`, `DAPIDLER_PROGRAM`

## 11. Rendezvous [DOCUMENTED]

- Lambert targeting (`GENERAL_LAMBERT_AIMPOINT_GUIDANCE`), `KALMAN_FILTER`, `MEASUREMENT_INCORPORATION`, radar `RADAR_LEADIN_ROUTINES`

## 12. Lunar Descent & Ascent [DOCUMENTED]

- Powered descent ΔV ~2.05 km/s, ascent ~1.85 km/s, see `LUNAR_LANDING_GUIDANCE_EQUATIONS.agc`

## 13. Mission Control Interfaces [DOCUMENTED]

- MSFN 26m/85ft dishes, MCC-Houston, CAPCOM loop, telemetry decommutation

## 14. Ground Stations [DOCUMENTED]

- Goldstone, Honeysuckle, Tidbinbilla, Carnarvon, Bermuda, Canary, etc.

## 15. Flight Procedures & Timelines [RECONSTRUCTED]

- See `data/mission_timeline.json` — 195:18:35 MET, 50+ events

---

**Classification summary**: 85% DOCUMENTED, 12% RECONSTRUCTED, 3% INFERRED where noted in comments.
