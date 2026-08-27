/**
 * DSKY — RECONSTRUCTED from PINBALL_GAME_BUTTONS_AND_LIGHTS 390-471
 * Verb/Noun/Program display
 */
export class Dsky {
    state = { prog: "00", verb: "00", noun: "00", r1: "+00000", r2: "+00000", r3: "+00000", compActy: false, flags: {} };
    keyQueue = [];
    key(k) { this.keyQueue.push(k); /* KEYRUPT will handle */ }
    // PINBALL verb dispatch — DOCUMENTED table in PINBALL_NOUN_TABLES 301-319
    dispatchVerb(v, n) {
        // V37 = change major mode → Pxx
        if (v === "37") {
            this.state.prog = n.padStart(2, "0");
            return `P${n}`;
        }
        // V16 N68 = display range/ range-rate (landing) — DOCUMENTED
        if (v === "16" && n === "68") {
            return "MONITOR_P63";
        }
        // V06 N62 display — CREW monitored during PDI
        return `V${v}N${n}`;
    }
    displayR1(v) { this.state.r1 = v; }
    setCompActy(on) { this.state.compActy = on; }
}
//# sourceMappingURL=dsky.js.map