/**
 * AGC Memory Organization — DOCUMENTED from ERASABLE_ASSIGNMENTS + TAGS_FOR_RELATIVE_SETLOC
 */

export const ERASABLE_SIZE = 2048;
export const FIXED_SIZE = 36 * 1024;

export interface ErasableCell {
  addrOct: string;
  symbol: string;
  init: number;
  evidence: string;
}

// Partial map — full 600+ in evidence/artifacts normalized JSON
export const ERASABLE_MAP: ErasableCell[] = [
  { addrOct: "0000", symbol: "A", init: 0, evidence: "R-393 DOCUMENTED" },
  { addrOct: "0001", symbol: "L", init: 0, evidence: "R-393 DOCUMENTED" },
  { addrOct: "0002", symbol: "Q", init: 0, evidence: "R-393 DOCUMENTED" },
  { addrOct: "0003", symbol: "EBANK", init: 0, evidence: "R-393" },
  { addrOct: "0004", symbol: "FBANK", init: 0, evidence: "R-393" },
  { addrOct: "0005", symbol: "Z", init: 0, evidence: "R-393" },
  { addrOct: "0027", symbol: "FLAGWRD0", init: 0, evidence: "FLAGWORD_ASSIGNMENTS pp.61" },
  // State vectors (double-precision)
  { addrOct: "01000", symbol: "RN", init: 0, evidence: "ERASABLE_ASSIGNMENTS 90-152" },
  { addrOct: "01006", symbol: "VN", init: 0, evidence: "ERASABLE_ASSIGNMENTS" },
  { addrOct: "01012", symbol: "PIPTIME", init: 0, evidence: "ERASABLE_ASSIGNMENTS" },
  { addrOct: "01400", symbol: "TGO", init: 0, evidence: "LUNAR_LANDING" },
];

export class AgcMemory {
  erasable = new Int16Array(ERASABLE_SIZE); // 1's complement modeled as 16-bit
  fixed: Int16Array;
  eb = 0; fb = 0; // bank registers
  channels = new Map<number, number>();

  constructor(fixedWords?: Int16Array) {
    this.fixed = fixedWords ?? new Int16Array(FIXED_SIZE);
  }

  /** 1's complement add — DOCUMENTED */
  add(a: number, b: number): number {
    let sum = (a & 0o77777) + (b & 0o77777);
    // end-around carry
    if (sum & 0o100000) sum = (sum & 0o77777) + 1;
    // overflow → keep 15 bits + sign handling TS will check
    return sum & 0o77777;
  }

  read(addr: number): number {
    if (addr < 0o2000) return this.erasable[addr];
    // fixed banked
    const bank = this.fb;
    const offset = addr - 0o2000;
    return this.fixed[bank * 1024 + offset] ?? 0;
  }

  write(addr: number, value: number) {
    if (addr < 0o2000) this.erasable[addr] = value & 0o77777;
    else throw new Error(`Write to fixed memory ${addr.toString(8)} — DOCUMENTED ROPE is read-only`);
  }

  readChannel(ch: number): number { return this.channels.get(ch) ?? 0; }
  writeChannel(ch: number, v: number) { this.channels.set(ch, v & 0o77777); }

  /** INFERRED: parity not modeled, stripped */
}
