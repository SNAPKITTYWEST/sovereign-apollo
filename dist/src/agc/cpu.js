import { decode } from "./isa.js";
export class AgcCpu {
    mem;
    state = { A: 0, L: 0, Q: 0, Z: 0, BB: 0, cycles: 0, inhibitInterrupts: false, extendNext: false, overflow: false };
    nextIndex = false;
    indexValue = 0;
    constructor(mem) { this.mem = mem; }
    /** Execute one instruction at current Z — DOCUMENTED fetch-decode-execute */
    step() {
        const addr = this.state.Z;
        const word = this.mem.read(addr);
        const dec = decode(word);
        this.state.Z = (this.state.Z + 1) & 0o7777;
        // Handle EXTEND prefix
        if (word === 0o000006) {
            this.state.extendNext = true;
            this.state.cycles += 1;
            return;
        }
        // Handle INDEX
        if (dec.opcode === 0o02) { // INDEX
            const v = this.mem.read(dec.addr);
            this.indexValue = v;
            this.nextIndex = true;
            this.state.cycles += 2;
            return;
        }
        let effAddr = dec.addr;
        if (this.nextIndex) {
            effAddr = (effAddr + this.indexValue) & 0o7777;
            this.nextIndex = false;
        }
        const isExt = this.state.extendNext;
        this.state.extendNext = false;
        switch (dec.opcode) {
            case 0o00: // TC
                this.state.Q = this.state.Z;
                this.state.Z = effAddr;
                this.state.cycles += 1;
                break;
            case 0o01: // CCS
                {
                    const m = this.mem.read(effAddr);
                    // 1's comp CCS: if m>0 A=m-1, if 0 CCS+1, if <0 A=-(m+1), if -0 CCS+2 etc — simplified
                    if (m === 0)
                        this.state.Z += 1;
                    else if ((m & 0o40000) === 0) {
                        this.state.A = (m - 1) & 0o77777;
                    }
                    else if (m === 0o77777)
                        this.state.Z += 2;
                    else {
                        this.state.A = (~m & 0o77777);
                        this.state.Z += 1;
                    }
                    this.state.cycles += 2;
                }
                break;
            case 0o03: // XCH
                {
                    const tmp = this.state.A;
                    this.state.A = this.mem.read(effAddr);
                    this.mem.write(effAddr, tmp);
                    this.state.cycles += 2;
                }
                break;
            case 0o04: // CS
                this.state.A = (~this.mem.read(effAddr) & 0o77777);
                this.state.cycles += 2;
                break;
            case 0o05: // TS — transfer to storage with overflow check
                {
                    const v = this.state.A;
                    // DOCUMENTED: if overflow (±37777) generate alarm, correct
                    if (v === 0o37777 || v === 0o40000) {
                        this.state.overflow = true; /* ALARM */
                    }
                    this.mem.write(effAddr, v);
                    this.state.cycles += 2;
                }
                break;
            case 0o06: // AD (1's complement)
                {
                    const m = this.mem.read(effAddr);
                    this.state.A = this.mem.add(this.state.A, m);
                    this.state.cycles += 2;
                }
                break;
            default:
                if (isExt)
                    this.execExtracode(dec.opcode, effAddr);
                else { // MASK
                    this.state.A &= this.mem.read(effAddr);
                    this.state.cycles += 2;
                }
        }
    }
    execExtracode(op, addr) {
        switch (op) {
            case 0o00: // READ
                this.state.A = this.mem.readChannel(addr);
                this.state.cycles += 2;
                break;
            case 0o01: // WRITE
                this.mem.writeChannel(addr, this.state.A);
                this.state.cycles += 2;
                break;
            case 0o04: // INCR
                {
                    const v = (this.mem.read(addr) + 1) & 0o77777;
                    this.mem.write(addr, v);
                    this.state.cycles += 2;
                }
                break;
            case 0o07: // DCA
                {
                    this.state.A = this.mem.read(addr);
                    this.state.L = this.mem.read((addr + 1) & 0o7777);
                    this.state.cycles += 3;
                }
                break;
            case 0o13: // BZMF
                if (this.state.A & 0o40000 || this.state.A === 0)
                    this.state.Z = addr;
                this.state.cycles += 2;
                break;
            default: this.state.cycles += 2; // INFERRED: unimplemented extracodes treated as NOP with timing
        }
    }
    reset() { this.state = { A: 0, L: 0, Q: 0, Z: 0, BB: 0, cycles: 0, inhibitInterrupts: false, extendNext: false, overflow: false }; }
}
//# sourceMappingURL=cpu.js.map