/**
 * Downlink telemetry — DOCUMENTED lists + MODERN hash chain
 */
import { createHash } from "node:crypto";
import { State } from "../mission/state.js";

export interface DownlinkWord { addrOct:string; symbol:string; valueOct:string; valueDec:number; }
export interface TelemetryFrame {
  met:string; metSeconds:number; listId:number; listName:string;
  words:DownlinkWord[]; syncWord:string;
  hashChain:{ prevHash:string; frameHash:string; algorithm:"SHA-256" };
}

const LISTS: Record<number,string> = {0:"ORBITAL",1:"POWERED",2:"LANDING"};
let prevHash = "0".repeat(64);

export function buildFrame(state:State, listId:number, words:DownlinkWord[]): TelemetryFrame {
  const payload = JSON.stringify({met:state.met, listId, words});
  const frameHash = createHash("sha256").update(prevHash+payload).digest("hex");
  const frame: TelemetryFrame = {
    met: state.met, metSeconds: state.metSeconds, listId, listName: LISTS[listId]??"UNKNOWN",
    words, syncWord:"0x7776", hashChain:{ prevHash, frameHash, algorithm:"SHA-256" }
  };
  prevHash=frameHash;
  return frame;
}

export function resetHash(){ prevHash="0".repeat(64); }

/** Build words from erasable symbols — DOCUMENTED addresses */
export function wordsFromState(state:State): DownlinkWord[] {
  // Minimal: RN, VN, PIPTIME, TGO etc.
  return [
    { addrOct:"01000", symbol:"RN1", valueOct: state.position[0].toString(8).slice(-5), valueDec: Math.round(state.position[0]) },
    { addrOct:"03400", symbol:"DNECADR", valueOct:"03412", valueDec:0o3412 },
  ];
}
