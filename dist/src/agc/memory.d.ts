/**
 * AGC Memory Organization — DOCUMENTED from ERASABLE_ASSIGNMENTS + TAGS_FOR_RELATIVE_SETLOC
 */
export declare const ERASABLE_SIZE = 2048;
export declare const FIXED_SIZE: number;
export interface ErasableCell {
    addrOct: string;
    symbol: string;
    init: number;
    evidence: string;
}
export declare const ERASABLE_MAP: ErasableCell[];
export declare class AgcMemory {
    erasable: Int16Array<ArrayBuffer>;
    fixed: Int16Array;
    eb: number;
    fb: number;
    channels: Map<number, number>;
    constructor(fixedWords?: Int16Array);
    /** 1's complement add — DOCUMENTED */
    add(a: number, b: number): number;
    read(addr: number): number;
    write(addr: number, value: number): void;
    readChannel(ch: number): number;
    writeChannel(ch: number, v: number): void;
}
