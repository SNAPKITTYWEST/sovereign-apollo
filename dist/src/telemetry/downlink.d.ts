import { State } from "../mission/state.js";
export interface DownlinkWord {
    addrOct: string;
    symbol: string;
    valueOct: string;
    valueDec: number;
}
export interface TelemetryFrame {
    met: string;
    metSeconds: number;
    listId: number;
    listName: string;
    words: DownlinkWord[];
    syncWord: string;
    hashChain: {
        prevHash: string;
        frameHash: string;
        algorithm: "SHA-256";
    };
}
export declare function buildFrame(state: State, listId: number, words: DownlinkWord[]): TelemetryFrame;
export declare function resetHash(): void;
/** Build words from erasable symbols — DOCUMENTED addresses */
export declare function wordsFromState(state: State): DownlinkWord[];
