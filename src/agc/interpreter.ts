/**
 * AGC Interpreter (VM) — RECONSTRUCTED
 * DOCUMENTED: INTERPRETER.agc 1002-1094, RTB_OP_CODES 1397-1402, INTER-BANK_COMMUNICATION 998-1001
 * Implements double-precision vector ops (28-bit: 2 words + sign, 1's complement)
 */

export type Vec3 = [number, number, number]; // double each? Simplified to JS number for deterministic replay
export type Mat3 = [Vec3, Vec3, Vec3];

function toDP(hi: number, lo: number): number {
  // 1's complement DP → JS number scaled — RECONSTRUCTED: scale 2^-14 per word
  const scale = 16384;
  let h = hi & 0o77777; if (h & 0o40000) h = - (~h & 0o37777)-1;
  let l = lo & 0o77777; if (l & 0o40000) l = - (~l & 0o37777)-1;
  return h + l/scale; // INFERRED scaling — sufficient for guidance invariants
}

export class AgcInterpreter {
  MPAC = new Float64Array(7); // DOCUMENTED 7-word accum
  stack: Float64Array[] = [];
  push(v: Float64Array) { this.stack.push(v.slice()); }
  pop(): Float64Array { return this.stack.pop()!; }

  // VM verbs — each maps to Luminary INTERPRETIVE op
  VLOAD(addr: Vec3): void { this.MPAC.set(addr as any); }
  VSU(b: Vec3): Vec3 { const a=[this.MPAC[0],this.MPAC[1],this.MPAC[2]] as Vec3; return [a[0]-b[0],a[1]-b[1],a[2]-b[2]] as Vec3; }
  VAD(b: Vec3): Vec3 { const a=[this.MPAC[0],this.MPAC[1],this.MPAC[2]] as Vec3; return [a[0]+b[0],a[1]+b[1],a[2]+b[2]] as Vec3; }
  DOT(b: Vec3): number { const a=[this.MPAC[0],this.MPAC[1],this.MPAC[2]] as Vec3; return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]; }
  UNIT(v: Vec3): Vec3 { const n=Math.hypot(v[0],v[1],v[2]); return n===0?[0,0,0] as Vec3:[v[0]/n,v[1]/n,v[2]/n] as Vec3; }
  VXM(m: Mat3): Vec3 { const v=[this.MPAC[0],this.MPAC[1],this.MPAC[2]] as Vec3;
    return [ v[0]*m[0][0]+v[1]*m[1][0]+v[2]*m[2][0], v[0]*m[0][1]+v[1]*m[1][1]+v[2]*m[2][1], v[0]*m[0][2]+v[1]*m[1][2]+v[2]*m[2][2]] as Vec3;
  }
  ABVAL(v: Vec3): number { return Math.hypot(v[0],v[1],v[2]); }

  /** Execute interpretive string — RECONSTRUCTED dispatcher */
  exec(ops: {op:string,arg?:any}[]): void {
    for (const {op,arg} of ops) {
      switch(op) {
        case "VLOAD": this.VLOAD(arg); break;
        case "VSU": { const r=this.VSU(arg); this.MPAC.set(r as any);} break;
        case "VAD": { const r=this.VAD(arg); this.MPAC.set(r as any);} break;
        case "DOT": this.MPAC[0]=this.DOT(arg); break;
        case "UNIT": { const v=[this.MPAC[0],this.MPAC[1],this.MPAC[2]] as Vec3; const u=this.UNIT(v); this.MPAC.set(u as any);} break;
        case "ABVAL": { const v=[this.MPAC[0],this.MPAC[1],this.MPAC[2]] as Vec3; this.MPAC[0]=this.ABVAL(v);} break;
        case "EXIT": return;
        default: /* INFERRED: unhandled op treated as NOP */ break;
      }
    }
  }
}
