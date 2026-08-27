# AGC Architecture Reconstruction

> Source: Luminary099 + MIT R-393 / R-500 + supplementals. Classification per section.

## 1. Overview [DOCUMENTED]

- **Block II AGC**: 16-bit word, 15 data + 1 parity (odd), 1's complement, 2.048 MHz master, 11.7 µs MCT
- **Memory**: 2048 words erasable (magnetic core, 2k), 36k words fixed (core rope, 36 banks × 1024)
- **Logic**: ~5600 3-input NOR gates (RTL), DSKY interface

## 2. Memory Organization [DOCUMENTED]

```
Erasable (RAM): 0000–1777 octal (0–2047 dec) — 2K
  - 0000–0013: Central registers (A, L, Q, Z, BB, etc.)
  - 0014–0037: Editing registers
  - 0040–1377: General (including FLAGWORDS, state vectors)
Fixed (ROM): 2000–77777 octal (36 banks ×1K = 36864 words)
  - Bank 0-1 always addressable; banks 2-35 via BB register
  - Super-bank bit for >36K (EB/FB)
```

Extracted from `ERASABLE_ASSIGNMENTS.agc` (90-152) and `FLAGWORD_ASSIGNMENTS.agc` (61-88) and `TAGS_FOR_RELATIVE_SETLOC.agc`.

Erasable map (partial, normalized in `src/agc/memory.ts`):

| Address (oct) | Symbol | Purpose | Evidence |
|---------------|--------|---------|----------|
| 0000 | A | Accumulator | DOCUMENTED |
| 0001 | L | Low product | DOCUMENTED |
| 0002 | Q | Return addr | DOCUMENTED |
| 0003 | EB/FB | Bank regs | DOCUMENTED |
| 0027 | FLAGWRD0 | Flags | FLAGWORD_ASSIGNMENTS |
| 01000 | STATE vectors | RN, VN, etc. | ERASABLE_ASSIGNMENTS |

Fixed banks: `CONTROLLED_CONSTANTS.agc` 38-53, `FIXED_FIXED_CONSTANT_POOL` 1095-1099.

## 3. Registers [DOCUMENTED]

| Reg | Bits | Function |
|-----|------|----------|
| A | 16 | Accumulator, 1's complement |
| L | 16 | Lower product / extension |
| Q | 16 | Return address (TC) |
| Z | 12 | Program counter (within bank) |
| BB | 16 | Bank register (EB 3b + FB 5b + super) |
| B | 16 | Instruction buffer |
| S | 12 | Memory addr |
| G | 16 | Memory buffer |
| EB/FB | — | Alias for BB fields |
| CYR/SR/Q loc | — | Editing |

## 4. Instruction Architecture [DOCUMENTED]

### Word format (15b + parity):
```
[15:13] opcode ext + [12:10] opcode + [9:0] address (K or 10b addr) + QC
Extracode (EC) prefix = 07/TC? Actually TC=01 ... see table.
```

### Instruction set (from `RTB_OP_CODES.agc`, `INTERPRETER.agc`):

| Opcode (oct) | Mnemonic | Function | Cycles (MCT) |
|--------------|----------|----------|--------------|
| 00 | TC | Transfer control | 1 |
| 01 | CCS | Count, compare, skip | 2 |
| 02 | INDEX | Index next instr | 2 |
| 03 | XCH | Exchange A&M | 2 |
| 04 | CS | Clear & subtract | 2 |
| 05 | TS | Transfer to storage (overflow check) | 2 |
| 06 | AD | Add (1's comp) | 2 |
| 10-17 ext | — | Extracode group | — |

**Extracode (preceded by EXTEND 000006):**

| Ext | Mnemonic | Function |
|-----|----------|----------|
| 00 | READ/WRITE | Channel I/O |
| 02 | DAS | Double add & store |
| 03 | LXCH | Exchange L |
| 04 | INCR | Increment |
| 05 | AUG | Augment |
| 06 | DIM (DIM?) | Diminish |
| 07 | DCA | Double fetch |
| 10 | DCS | Double clear/sub |
| 11 | ND? / INDEX? | — |
| 12 | SU | Subtract |
| 13 | BZMF | Branch zero/minus |
| 14 | MP | Multiply (SP) |
| 15 | — | — |
| 20 | DV | Divide |
| etc | — | — |

Interrupt + invol + `INHINT/RELINT`, `EXTEND`, `RESUME`.

**NOTE**: Full opcode table normalized in `src/agc/isa.ts` and verified against `yaYUL` assembler.

### Timing [DOCUMENTED]

- Master 2.048 MHz → MCT 11.7 µs (12 pulses)
- Most instructions 1-2 MCT; MP 3, DV 6.
- Counter increments via 5-stage scaler; TIME1/TIME2/TIME6 drive interrupts.

## 5. Interrupts [DOCUMENTED]

From `INTERRUPT_LEAD_INS.agc` 153-154, `T4RUPT_PROGRAM.agc`, `KEYRUPT_UPRUPT.agc`:

| Vector | Source | Priority | Handler |
|--------|--------|----------|---------|
| T6 | Clock, 100ms | High | T6RUPT (DAP/RCS) |
| T5 | Clock, variable |  | WAITLIST |
| T4 | Clock, 120ms |  | DSKY/ RCS? Actually T4RUPT pp.155-189 |
| T3 | Clock, 100ms? |  | — |
| KEYRUPT1/2 | DSKY key |  | KEYRUPT |
| UPRUPT | Uplink |  | UPRUPT |
| COUNTER | Overflows |  | — |

Interrupt behavior: `INHINT` blocks, `RESUME` returns, priority queue, `RUPTREG` saves.

## 6. I/O Channels [DOCUMENTED]

From `INPUT_OUTPUT_CHANNEL_BIT_DESCRIPTIONS.agc` 54-60:

| Channel (oct) | Name | Dir | Use |
|---------------|------|-----|-----|
| 005 | PYJETS | Out | RCS pitch jets |
| 006 | ROLLJETS | Out | Roll |
| 010 | — | Out | Engine on/off, gimbal |
| 012 | OPTICS | In/Out | CDU, optics |
| 013 | — | — | Hand controller |
| 015 | — | — | Display |
| 030-033 | — | In | DSKY keys |
| 034-035 | — | — | Uplink/downlink |
| 077 | — | Out | Restart light |

Normalized in `src/agc/memory.ts` channels map.

## 7. Executive (Cooperative Multitasking) [DOCUMENTED]

From `EXECUTIVE.agc` 1103-1116:

- **EXECUTIVE**: priority queue, 7 priority levels, `NOVAC`, `FINDVAC`, `CHANGEJOB`
- Up to 8 jobs (switchable via `VAC` areas)
- `WAITLIST` (1117-1132): long-call queue at fixed delays (T5 timers), `LONGCALL` macro
- `PHASE TABLE` (1294-1302): restart protection — 6×2 flagwords, per-job phase; `PHASE TABLE MAINTENANCE.agc`
- `FRESH_START_AND_RESTART.agc` (211-237): cold start vs warm restart, `RESTART_TABLES` (238-243), `RESTARTS_ROUTINE` (1303-1308)

**Restart behavior**: On `GOJAM` or power transient, hardware forces `FRESH START`; software walks RESTART table, resumes highest phase. **Proof of 1202 handling**: under capacity, Exec drops low-priority jobs, raises `1202` alarm via `ALARM_AND_ABORT.agc` (1381-1385).

## 8. Interpreter (Virtual Machine) [DOCUMENTED]

From `INTERPRETER.agc` 1002-1094 + `INTERPRETIVE_CONSTANT` 1100-1101:

- Stack VM for vector double-precision (28-bit: 2 words + sign) — 5-deep stack? Actually `MPAC` 7 words.
- Opcode `RTB_OP_CODES.agc` 1397-1402: `VADD`, `VSUB`, `VXM`, `MXV`, `DOT`, `UNIT`, `ABVAL`, `VSQ`, `BVSU`, `BPL`, `BHIZ`, `CALL`, `EXIT`, `DLOAD`, `STORE`, `STODL`, etc. (~100 ops)
- Interpretive acceleration via `BANKCALL` / `INTER-BANK_COMMUNICATION.agc` 998-1001

Reimplemented in `src/agc/interpreter.ts` as deterministic TypeScript — cycle-counted but not cycle-accurate to NOR.

## 9. DSKY Interface [DOCUMENTED]

From `PINBALL_GAME_BUTTONS_AND_LIGHTS.agc` 390-471, `DISPLAY_INTERFACE_ROUTINES` 1341-1373, `PINBALL_NOUN_TABLES` 301-319:

- **Keys**: Verb (V), Noun (N), +/-, numbers 0-9, PRO, KEY REL, RSET, ENTR
- **Displays**: 3× 5-digit + sign (R1/R2/R3), Verb 2-digit, Noun 2-digit, Program Major Mode
- **Mechanism**: DSKY → KEYRUPT → `PINBALL` executive job → noun tables → `EXECUTIVE`

Verbs 35/36/37 (lambert targeting), 16/06 monitor, 37 = change major mode (P00→P11...).

## 10. Guidance Programs & Navigation Routines [DOCUMENTED]

See `AGC_SOFTWARE_ANALYSIS.md`. Summary:

- **Executive + Waitlist + T4RUPT + Servicer** = 2-second outer loop
- **FINDCDUW + GIMBAL_LOCK_AVOIDANCE + KALCMANU** = attitude
- **P40-P47 + BURN_BABY_BURN + CROSS-PRODUCT STEERING** = powered flight
- **LUNAR_LANDING_GUIDANCE_EQUATIONS + THROTTLE_CONTROL** = PDI
- **KALMAN_FILTER + MEASUREMENT_INCORPORATION + ORBITAL_INTEGRATION** = navigation

## 11. Fault Handling & Restarts [DOCUMENTED]

- `ALARM_AND_ABORT.agc`: alarm codes 01xxx/02xxx/03xxx etc.; `POODOO` (abort), `BAILOUT` (recoverable)
- `RESTART_TABLES`: phase -2..+? ; 1201/1202 = executive overflow
- `AGC_BLOCK_TWO_SELF_CHECK.agc` 1284-1293: ROPE check, memory test

## 12. Implementation Notes [MODERN DESIGN]

- `src/agc/cpu.ts` implements documented ISA; **RECONSTRUCTED** not flight-equivalent
- Timing is count-accurate to MCT where documented; NOR-gate accurate not attempted (labeled INFERRED where missing)
- Original source preserved verbatim in `evidence/artifacts/Luminary099/`; reimplementation in `src/agc/` is separate

## References

- Luminary099 listings pp.1-1743
- Hall System Design (1963), Battin
- Virtual AGC Project yaAGC documentation
