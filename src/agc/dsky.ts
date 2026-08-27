/**
 * DSKY — RECONSTRUCTED from PINBALL_GAME_BUTTONS_AND_LIGHTS 390-471
 * Verb/Noun/Program display
 */

export type DskyKey = "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"VERB"|"NOUN"|"ENTR"|"CLR"|"PRO"|"KEY_REL"|"RSET"|"+/-";
export interface DskyState {
  prog: string; // Major Mode e.g., P63
  verb: string; // 2 digits
  noun: string; // 2 digits
  r1: string; r2: string; r3: string;
  compActy: boolean;
  flags: Record<string, boolean>;
}

export class Dsky {
  state: DskyState = { prog:"00", verb:"00", noun:"00", r1:"+00000", r2:"+00000", r3:"+00000", compActy:false, flags:{} };
  keyQueue: DskyKey[] = [];

  key(k: DskyKey) { this.keyQueue.push(k); /* KEYRUPT will handle */ }

  // PINBALL verb dispatch — DOCUMENTED table in PINBALL_NOUN_TABLES 301-319
  dispatchVerb(v:string, n:string) {
    // V37 = change major mode → Pxx
    if (v==="37") { this.state.prog = n.padStart(2,"0"); return `P${n}`; }
    // V16 N68 = display range/ range-rate (landing) — DOCUMENTED
    if (v==="16" && n==="68") { return "MONITOR_P63"; }
    // V06 N62 display — CREW monitored during PDI
    return `V${v}N${n}`;
  }

  displayR1(v:string){ this.state.r1=v; }
  setCompActy(on:boolean){ this.state.compActy=on; }
}
