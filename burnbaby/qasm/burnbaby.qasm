// burnbaby.qasm  —  OpenQASM 3.0 Quantum Ignition Circuit
// Maps the AGC BURNBABY state machine to a quantum execution model.
//
// Physical motivation:
//   The WHICH register (P12/P40/P42/P63) is in superposition until the
//   TIG-5 astronaut prompt (V99NXX "Please Enable Engine") forces
//   wave-function collapse.  Propellant ullage settling is modeled via
//   a parameterized Rx rotation seeded by ANU vacuum entropy.
//
// Classical AGC gates preserved:
//   TGO ≤ 0  (temporal gate)   → measured by classical control
//   ASTNFLAG (consent gate)    → measurement collapse at TIG-5
//   UllageSettled              → rx(theta_anu) on ullage_slosh qubit
//
// Target: IBM Heron / any OpenQASM 3.0 compatible backend

OPENQASM 3.0;
include "stdgates.inc";

// ── Quantum state registers ───────────────────────────────────────────────

qubit engine_state;       // |0⟩ = Idle  |1⟩ = Thrust
qubit[2] which_reg;       // Superposition of P12(00) P40(01) P42(10) P63(11)
qubit ullage_slosh;       // Physical propellant settling variance

// ── Classical output registers ────────────────────────────────────────────

bit ign_flag;             // Final engine-on flag
bit[2] profile_selected;  // Which program collapsed to
bit ullage_ok;            // Ullage settling measurement

// ── TIG-35: Initialize superposition of all mission profiles ──────────────
// AGC: Janet(WHICH, 5) selects the program spot. Quantum: H gates create
// equal-weight superposition of all four profiles.

h which_reg[0];
h which_reg[1];

// ── TIG-30: Ullage settling via ANU vacuum entropy ────────────────────────
// theta_anu is a rotation angle [0, π/4] sampled from
// the ANU Quantum Random Number Generator.
// In simulation: use a fixed angle; in hardware: read live entropy.

input float theta_anu;
rx(theta_anu) ullage_slosh;

// ── TIG-5: Astronaut consent collapse ─────────────────────────────────────
// Measurement forces WHICH into a definite program, mirroring the crew's
// "V99 PROCEED" collapsing the guidance computer's program selector.

measure which_reg -> profile_selected;

// Classical gate: abort if profile is undefined (should not occur)
if (profile_selected == 3) {
  // P63 (PDI): additional zoom timing
  x ullage_slosh;   // assert slosh model update
}

// ── TIG-0: IGNYET? Collapse ───────────────────────────────────────────────
// Engine fires iff ullage has settled (|0⟩) AND astronaut enabled.
// CX maps: if ullage_slosh == |0⟩ then flip engine_state to |1⟩.
//
// Classical ASTNFLAG check is enforced at circuit dispatch level
// (Rust orchestrator must confirm astronaut_enabled before submitting).

ctrl @ x ullage_slosh, engine_state;

// Measure ullagee settling into classical bit
measure ullage_slosh -> ullage_ok;

// ── Ignition measurement ──────────────────────────────────────────────────
// Final collapse: is the engine on?

measure engine_state -> ign_flag;

// ── Post-processing (classical) ───────────────────────────────────────────
// In a hardware run, ign_flag → write DSALMOUT bit 13 via I/O bridge.
// If ign_flag == 0, recycle to TIG-0 (WAITABIT path in Janet table).
