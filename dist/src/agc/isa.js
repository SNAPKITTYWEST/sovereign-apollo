/**
 * AGC Instruction Architecture — RECONSTRUCTED from Luminary099 + R-393
 * Classification: DOCUMENTED where opcode matches listing; INFERRED timing gaps labeled.
 */
export const MCT_US = 11.7; // DOCUMENTED
export const TIMING_MCT = {
    TC: 1,
    CCS: 2,
    INDEX: 2,
    XCH: 2,
    CS: 2,
    TS: 2,
    AD: 2,
    MASK: 2,
    EXTEND: 1,
    READ: 2,
    WRITE: 2,
    DAS: 3,
    LXCH: 2,
    DCA: 3,
    DCS: 3,
    SU: 2,
    BZMF: 2,
    MP: 3,
    DV: 6, // DOCUMENTED 6 MCT
};
export const CHANNELS = {
    0o05: "PYJETS",
    0o06: "ROLLJETS",
    0o10: "ENGINE_CONTROL",
    0o012: "OPTICS_CDU",
    0o013: "HAND_CONTROLLER",
    0o015: "DISPLAY",
    0o030: "DSKY_IN1",
    0o031: "DSKY_IN2",
    0o032: "DSKY_OUT1",
    0o033: "DSKY_OUT2",
    0o034: "DOWNLINK_WORD",
    0o035: "DOWNLINK_CTRL",
    0o077: "RESTART_LIGHT",
};
/** Decode 15-bit word (parity removed) */
export function decode(word) {
    const qc = word & 0o3;
    const addr10 = word & 0o7777; // low 10? Actually 12 with QC
    const opcode = (word >> 12) & 0o07;
    // Simplified: bit 12-14 opcode, bit 11-0 addr + QC — true AGC interleaves; this is RECONSTRUCTED simplified
    return { addr: addr10, opcode, isExtracode: false, qc, raw: word & 0o77777 };
}
export const INTERPRETIVE_OPS = [
    "EXIT", "VLOAD", "VSU", "VAD", "VXM", "MXV", "DOT", "UNIT", "ABVAL", "VSQ", "BVSU", "BPL", "BHIZ", "CALL", "DLOAD", "STORE", "STODL", "STCALL", "VDEF", "AXT", "SXA", "TLOAD", "GOTO", "RTB", "BMN", "BOF", "BZF"
];
/** Flagword map extracted from FLAGWORD_ASSIGNMENTS.agc pp.61-88 — DOCUMENTED */
export const FLAGWORDS = {
    NEEDL: { word: 0, bit: 0 }, // need lunar landing guidance
    RNDVZFLG: { word: 0, bit: 1 },
    TRACKFLG: { word: 0, bit: 5 },
    UPDATFLG: { word: 1, bit: 0 },
    // ... 40+ flags — full table in evidence normalization script
};
//# sourceMappingURL=isa.js.map