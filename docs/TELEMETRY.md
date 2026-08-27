# Telemetry Model

## Downlink — LM [DOCUMENTED]

### Mechanism (from Luminary099)

- **Scheduler**: `DOWN_TELEMETRY_PROGRAM.agc` 988-997 runs at `T4RUPT`/Servicer; every 20ms writes one word to channel 34.
- **Lists**: `DOWNLINK_LISTS.agc` 193-205 defines ~100-word lists; `DNECADR`/`DNADR` point to next word.
- **Lists** (excerpt):
  - List 0: Orbital coast (state vector)
  - List 1: Powered flight (guidance vars)
  - List 2: Landing (LR altitude, throttle)
  - Cost +1, +2: special
- **Rate**: 51.2 kbps PCM to S-band (LGC → PCMTEA). 1 word = 16b + parity.

### Normalized Schema (RECONSTRUCTED)

See `data/telemetry_schema.json`. Each frame:

```json
{
  "met": "102:45:03",
  "list_id": 2,
  "words": [{"addr": "01410", "symbol": "RN1", "value": 1234}, ...],
  "sync": 0x7776
}
```

Modern wrapper: CCSDS-like header is **MODERN DESIGN** for replay; original words preserved verbatim in `words`.

### Channels

- Channel 34: downlink word; Channel 35: control; buffered via `COMFAIL` logic.

## Uplink [DOCUMENTED]

- Via `KEYRUPT_UPRUPT.agc` 1338-1340 → `UPDATE_PROGRAM.agc` 1386-1396
- Verbs: `V71` (peripheral), `V72` (incremental load), `V73` (octal load)
- Ground sends state vector updates, clock sync, program changes.

## Communications State [DOCUMENTED]

| Link | Freq | Power | Antenna | When |
|------|------|-------|---------|------|
| LM S-band steerable | 2287.5 MHz | 20W | 26-in dish (steered via S-BAND_ANTENNA_FOR_LM 486-489) | Lunar orbit+surface |
| LM S-band omni | 2287.5 | 0.5W | Omni | Ascent/descent backup |
| CSM S-band HGA | 2287.5 | 20W | 4× horns, gimbaled | All phases |
| CSM/LM VHF | 259.7/296.8 MHz | 5W | — | Rendezvous, EVA |
| MSFN | S-band | — | 85ft/26m dishes | Ground |

`S-BAND_ANTENNA_FOR_LM.agc` computes gimbal angles from `stable member` to Earth.

## Telemetry Integrity [MODERN DESIGN]

- Every downlink word hash-chained: `H_n = SHA256(H_{n-1} || word || MET)` — `src/telemetry/downlink.ts`
- Deterministic replay hashes enable integrity verification without crypto hardware.

## Ground Decommutation [RECONSTRUCTED]

- MSFN → MCC-H: decommutation via `Frame Sync` (Barker), word routing to GUIDO/FDO.
- Simulated in `src/telemetry/comms.ts` as state machine: `ACQUIRE → LOCK → DATA → DROP`.

## Fault Injection [MODERN DESIGN]

- Tools: `src/replay/fault.ts` can drop words, flip bits, induce `COMFAIL`, or overflow exec to trigger 1202.
