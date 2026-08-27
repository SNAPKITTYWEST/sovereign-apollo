# Mission Control Interface Model

## MCC-Houston Topology [DOCUMENTED]

### Consoles (Flight Control Team)

| Position | Call | Responsibility | Telemetry Streams |
|----------|------|----------------|-------------------|
| FLIGHT | Flight | Overall | All |
| CAPCOM | — | Crew comms | Voice |
| GUIDO | Guidance | AGC state, state vector | Downlink lists |
| FDO | FIDO | Trajectories, burns | Tracking |
| RETRO | — | Reentry | — |
| EECOM | — | Electrical, ECS | EPS/ECU words |
| GNC | — | Guidance & Control | DAP, IMU |
| CONTROL | — | LM guidance | LM downlink |
| NETWORK | — | MSFN | Signal strength |

Model: `src/telemetry/comms.ts` routes frames to virtual consoles.

## MSFN Ground Stations [DOCUMENTED]

```
Goldstone (DSS-14 64m) ─┐
Honeysuckle Creek (85ft)┤
Tidbinbilla (Carnarvon)─┼─→ Houston NASCOM → MCC-H  (voice + telemetry)
Carnarvon (Woomera) ────┤
Bermuda / Canary / etc ─┘
```

During PDI, dual coverage: Goldstone + Honeysuckle at 102:33 MET.

## Voice Loops [RECONSTRUCTED from transcripts]

- `AIR-TO-GROUND`
- `GUIDO`
- `FDO`
- `CAPCOM`

Each logged with MET in `data/mission_timeline.json` via `ground_events`.

## Uplink Flows [DOCUMENTED]

```
MCC-H (GUIDO) → MSFN  → V35/V71 → LGC (UPDATE_PROGRAM)
                2 kbps PCM
```

Example: state vector update P30 before TEI at 135:23 MET; handled by `UPDATE_PROGRAM.agc`.

## Display Model — Local Mission Control [MODERN DESIGN]

Sovereign provides a local-first MCC mimic without cloud:

```
src/sovereign/local-first.ts  →  offline Electron/web dashboard
  ├── telemetry decommutation (downlink lists)
  ├── trajectory plot (Servicer state vectors)
  ├── DSKY mirror (WebDSKY)
  └── voice timeline (transcript sync)
```

All data offline; sync via file ingestion, not proprietary cloud.

## Deterministic Replay Interface

```
Deterministic Replay Engine (src/replay/deterministic.ts)
  → emits frames: {MET, vehicle_state, guidance_mode, comms, telemetry, crew_proc, ground_event}
  → mission control renderer consumes same frames as real MSFN
```

This enables repeatable “what-if” analysis (e.g., remove 1202).
