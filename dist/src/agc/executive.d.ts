/**
 * Executive + Waitlist + Phase Table — DOCUMENTED from EXECUTIVE.agc 1103-1116 etc.
 */
export type JobPriority = 0 | 1 | 2 | 3 | 4 | 5 | 6;
export interface Job {
    id: number;
    priority: JobPriority;
    pc: number;
    vacArea: number;
    wakeTime?: number;
    phase: number;
}
export declare class Executive {
    jobs: Job[];
    waitlist: {
        time: number;
        job: Job;
    }[];
    phaseTable: Map<number, number>;
    time: number;
    maxJobs: number;
    novac(priority: JobPriority, pc: number): Job | null;
    endOfJob(jobId: number): void;
    longcall(delayCs: number, job: Job): void;
    tick(dtCs?: number): void;
    setPhase(jobId: number, phase: number): void;
    getPhase(jobId: number): number;
}
export declare class ExecOverflowError extends Error {
    code: string;
    constructor(msg: string);
}
export declare class RestartManager {
    private exec;
    private tables;
    constructor(exec: Executive, tables: Map<number, number>);
    /** FRESH_START_AND_RESTART pp.211-237 logic */
    restart(): void;
}
