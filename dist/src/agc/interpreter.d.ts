/**
 * AGC Interpreter (VM) — RECONSTRUCTED
 * DOCUMENTED: INTERPRETER.agc 1002-1094, RTB_OP_CODES 1397-1402, INTER-BANK_COMMUNICATION 998-1001
 * Implements double-precision vector ops (28-bit: 2 words + sign, 1's complement)
 */
export type Vec3 = [number, number, number];
export type Mat3 = [Vec3, Vec3, Vec3];
export declare class AgcInterpreter {
    MPAC: Float64Array<ArrayBuffer>;
    stack: Float64Array[];
    push(v: Float64Array): void;
    pop(): Float64Array;
    VLOAD(addr: Vec3): void;
    VSU(b: Vec3): Vec3;
    VAD(b: Vec3): Vec3;
    DOT(b: Vec3): number;
    UNIT(v: Vec3): Vec3;
    VXM(m: Mat3): Vec3;
    ABVAL(v: Vec3): number;
    /** Execute interpretive string — RECONSTRUCTED dispatcher */
    exec(ops: {
        op: string;
        arg?: any;
    }[]): void;
}
