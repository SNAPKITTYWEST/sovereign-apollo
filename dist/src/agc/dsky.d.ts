/**
 * DSKY — RECONSTRUCTED from PINBALL_GAME_BUTTONS_AND_LIGHTS 390-471
 * Verb/Noun/Program display
 */
export type DskyKey = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "VERB" | "NOUN" | "ENTR" | "CLR" | "PRO" | "KEY_REL" | "RSET" | "+/-";
export interface DskyState {
    prog: string;
    verb: string;
    noun: string;
    r1: string;
    r2: string;
    r3: string;
    compActy: boolean;
    flags: Record<string, boolean>;
}
export declare class Dsky {
    state: DskyState;
    keyQueue: DskyKey[];
    key(k: DskyKey): void;
    dispatchVerb(v: string, n: string): string;
    displayR1(v: string): void;
    setCompActy(on: boolean): void;
}
