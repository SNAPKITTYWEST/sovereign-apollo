import { State } from "../mission/state.js";
export interface ReplayFrame {
    state: State;
    telemetry: any;
    crewProc: string;
    groundEvent?: string;
    hash: string;
}
export declare class DeterministicReplay {
    private hash;
    private states;
    private cursor;
    private log;
    constructor(timelinePath?: string);
    private canonical;
    step(): ReplayFrame | null;
    replayAll(): {
        frames: ReplayFrame[];
        finalHash: string;
    };
    get finalHash(): string;
    /** INFERRED: compare two replays — should be bit-identical if deterministic */
    static verifyDeterminism(path?: string): boolean;
}
