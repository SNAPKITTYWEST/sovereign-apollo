/**
 * Deterministic Replay Engine — MODERN DESIGN
 * Emits {MET, vehicle_state, guidance_mode, propulsion, comms, telemetry, crew_proc, ground_event}
 * Hash-chained for verification.
 */
import { createHash } from "node:crypto";
import { State, metToString } from "../mission/state.js";
import { buildFrame, wordsFromState, resetHash } from "../telemetry/downlink.js";
import { loadTimeline, eventsToStates } from "../mission/timeline.js";

export interface ReplayFrame {
  state: State;
  telemetry: any;
  crewProc: string;
  groundEvent?: string;
  hash:string;
}

export class DeterministicReplay {
  private hash="0".repeat(64);
  private states: State[];
  private cursor=0;
  private log: ReplayFrame[]=[];

  constructor(timelinePath="data/mission_timeline.json"){
    const events=loadTimeline(timelinePath);
    this.states=eventsToStates(events);
    resetHash();
  }

  private canonical(state:State): string {
    // deterministic serialization — sorted keys, fixed precision
    return JSON.stringify({
      met: state.met, vehicle: state.vehicle, mode: state.guidanceMode,
      pos: state.position.map(v=>v.toFixed(2)),
      vel: state.velocity.map(v=>v.toFixed(2)),
      mass: state.massKg.toFixed(2)
    });
  }

  step(): ReplayFrame | null {
    if(this.cursor>=this.states.length) return null;
    const s=this.states[this.cursor++];
    const tel=buildFrame(s, s.guidanceMode==="P63"||s.guidanceMode==="P64"?2:0, wordsFromState(s));
    const h=createHash("sha256").update(this.hash + this.canonical(s)).digest("hex");
    this.hash=h;
    const f:ReplayFrame={ state:s, telemetry:tel, crewProc: s.alarm??"", groundEvent: s.alarm, hash:h };
    this.log.push(f);
    return f;
  }

  replayAll(): {frames:ReplayFrame[], finalHash:string} {
    resetHash(); this.hash="0".repeat(64); this.cursor=0; this.log=[];
    let f; while((f=this.step())!==null){}
    return { frames: this.log, finalHash:this.hash };
  }

  get finalHash(){ return this.hash; }

  /** INFERRED: compare two replays — should be bit-identical if deterministic */
  static verifyDeterminism(path="data/mission_timeline.json"): boolean {
    const a=new DeterministicReplay(path).replayAll().finalHash;
    const b=new DeterministicReplay(path).replayAll().finalHash;
    return a===b;
  }
}
