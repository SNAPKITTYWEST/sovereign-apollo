/**
 * AGC Instruction Architecture — RECONSTRUCTED from Luminary099 + R-393
 * Classification: DOCUMENTED where opcode matches listing; INFERRED timing gaps labeled.
 */
export declare const enum Opcode {
    TC = 0,// Transfer Control
    CCS = 1,// Count, Compare, Skip
    INDEX = 2,
    XCH = 3,
    CS = 4,
    TS = 5,
    AD = 6,
    MASK = 7
}
export declare const enum ExtOpcode {
    READ = 0,
    WRITE = 1,
    DAS = 2,
    LXCH = 3,
    INCR = 4,
    AUG = 5,
    DIM = 6,
    DCA = 7,
    DCS = 8,
    ND00 = 9,
    SU = 10,
    BZMF = 11,
    MP = 12,
    DV = 16
}
export interface Instruction {
    addr: number;
    opcode: number;
    isExtracode: boolean;
    qc: number;
    raw: number;
}
export declare const MCT_US = 11.7;
export declare const TIMING_MCT: Record<string, number>;
export declare const CHANNELS: Record<number, string>;
/** Decode 15-bit word (parity removed) */
export declare function decode(word: number): Instruction;
export declare const INTERPRETIVE_OPS: readonly ["EXIT", "VLOAD", "VSU", "VAD", "VXM", "MXV", "DOT", "UNIT", "ABVAL", "VSQ", "BVSU", "BPL", "BHIZ", "CALL", "DLOAD", "STORE", "STODL", "STCALL", "VDEF", "AXT", "SXA", "TLOAD", "GOTO", "RTB", "BMN", "BOF", "BZF"];
export type InterpOp = typeof INTERPRETIVE_OPS[number];
/** Flagword map extracted from FLAGWORD_ASSIGNMENTS.agc pp.61-88 — DOCUMENTED */
export declare const FLAGWORDS: Record<string, {
    word: number;
    bit: number;
}>;
