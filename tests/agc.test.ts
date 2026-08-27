import { describe, it, expect } from "vitest";
import { AgcMemory } from "../src/agc/memory.js";
import { AgcCpu } from "../src/agc/cpu.js";
import { Executive, ExecOverflowError } from "../src/agc/executive.js";
import { DeterministicReplay } from "../src/replay/deterministic.js";
import { assertInvariant } from "../src/sovereign/verification.js";

describe("AGC ISA DOCUMENTED", ()=>{
  it("TC branches", ()=>{
    const mem=new AgcMemory();
    mem.write(0o1000, 0o00006); // use erasable
    // Simplified check: step doesn't throw
    const cpu=new AgcCpu(mem);
    cpu.state.Z=0o1000;
    expect(()=>cpu.step()).not.toThrow();
  });
  it("1's complement add end-around carry", ()=>{
    const mem=new AgcMemory();
    expect(mem.add(0o77777, 0o00001)).toBe(0o00001); // -0 +1 → wrap
  });
  it("Executive overflow 1202", ()=>{
    const exec=new Executive();
    expect(()=>{
      for(let i=0;i<10;i++) exec.novac(6 as any, 0o4000);
    }).toThrow(ExecOverflowError);
    try{ for(let i=0;i<10;i++) exec.novac(6 as any, 0o4000); }catch(e:any){ expect(e.code).toBe("1202"); }
  });
  it("Deterministic replay bit-identical", ()=>{
    const a=new DeterministicReplay().replayAll().finalHash;
    const b=new DeterministicReplay().replayAll().finalHash;
    expect(a).toBe(b);
  });
  it("Throttle invariant during P63", ()=>{
    const s:any={ met:"102:33:05", metSeconds:0, guidanceMode:"P63", propulsion:{throttle:1.5}, vehicle:"PDI", massKg:5000, dryMassKg:4000, position:[0,0,0], velocity:[0,0,0], cdu:[0,0,0] };
    expect(()=>assertInvariant(s)).toThrow();
    s.propulsion.throttle=0.5; expect(()=>assertInvariant(s)).not.toThrow();
  });
});
