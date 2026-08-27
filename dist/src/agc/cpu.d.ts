/**
 * AGC CPU — RECONSTRUCTED deterministic model
 * Preserves 1's complement, overflow, TS, INDEX, EXTEND semantics.
 * Not NOR-gate accurate (labeled INFERRED where simplified).
 */
import { AgcMemory } from "./memory.js";
export interface CpuState {
    A: number;
    L: number;
    Q: number;
    Z: number;
    BB: number;
    cycles: number;
    inhibitInterrupts: boolean;
    extendNext: boolean;
    overflow: boolean;
}
export declare class AgcCpu {
    mem: AgcMemory;
    state: CpuState;
    nextIndex: boolean;
    indexValue: number;
    constructor(mem: AgcMemory);
    /** Execute one instruction at current Z — DOCUMENTED fetch-decode-execute */
    step(): void;
    private execExtracode;
    reset(): void;
}
