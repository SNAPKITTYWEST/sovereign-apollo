/**
 * Fault Injection — MODERN DESIGN
 * Candidate faults: executive overflow (1202), comm dropout, engine transient, IMU drift
 */
import { Executive } from "../agc/executive.js";
import { DeterministicReplay } from "./deterministic.js";
export type FaultKind = "1202" | "1201" | "COM_DROP" | "DPS_THROTTLE_STUCK" | "IMU_DRIFT";
export interface FaultSpec {
    kind: FaultKind;
    atMet: string;
    durationS?: number;
    magnitude?: number;
}
export declare class FaultInjector {
    private exec?;
    constructor(exec?: Executive | undefined);
    inject(spec: FaultSpec, replay: DeterministicReplay): void;
    static fromCli(args: string[]): FaultSpec;
}
