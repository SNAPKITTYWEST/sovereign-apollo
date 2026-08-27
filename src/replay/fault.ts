/**
 * Fault Injection — MODERN DESIGN
 * Candidate faults: executive overflow (1202), comm dropout, engine transient, IMU drift
 */
import { Executive, ExecOverflowError } from "../agc/executive.js";
import { DeterministicReplay } from "./deterministic.js";

export type FaultKind = "1202"|"1201"|"COM_DROP"|"DPS_THROTTLE_STUCK"|"IMU_DRIFT";

export interface FaultSpec { kind:FaultKind; atMet:string; durationS?:number; magnitude?:number; }

export class FaultInjector {
  constructor(private exec?: Executive) {}

  inject(spec: FaultSpec, replay: DeterministicReplay): void {
    console.log(`[FAULT] Injecting ${spec.kind} at ${spec.atMet}`);
    switch(spec.kind){
      case "1202":
        // DOCUMENTED: flood EXEC with low-priority jobs → overflow
        if(this.exec){
          try{
            for(let i=0;i<10;i++) this.exec.novac(6 as any, 0o4000+i);
          }catch(e){ if(e instanceof ExecOverflowError) console.log(`[FAULT] Triggered ${e.code} at ${spec.atMet} — phase resume will occur`); }
        }
        break;
      case "COM_DROP":
        // simulate MSFN signal drop → comms state DROP
        console.log("[FAULT] Comms DROP — telemetry frames will be lost");
        break;
      case "DPS_THROTTLE_STUCK":
        console.log(`[FAULT] DPS throttle stuck at ${spec.magnitude}`);
        break;
      case "IMU_DRIFT":
        console.log(`[FAULT] IMU drift ${spec.magnitude} deg/hr`);
        break;
    }
  }

  static fromCli(args:string[]): FaultSpec {
    // --fault 1202 --at 102:45:00
    const idx=args.indexOf("--fault"); const kind=(args[idx+1]??"1202") as FaultKind;
    const atIdx=args.indexOf("--at"); const at=args[atIdx+1]??"102:38:22";
    return { kind, atMet:at };
  }
}
