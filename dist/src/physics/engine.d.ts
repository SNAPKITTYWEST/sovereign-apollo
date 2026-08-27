/**
 * Physics Engine — MODERN DESIGN preserving Apollo constraints
 * Deterministic fixed-step; drives Servicer 2-s cycle
 */
import { State } from "../mission/state.js";
export interface PhysicsConfig {
    dtMs: number;
    servicerPeriodMs: number;
}
export declare const DEFAULT_CONFIG: PhysicsConfig;
export declare class PhysicsEngine {
    state: State;
    tMs: number;
    servicerAccum: number;
    cfg: PhysicsConfig;
    constructor(initial: State, cfg?: PhysicsConfig);
    /** Deterministic step — no Date.now, no random without seed */
    step(dtMs?: number): void;
    private servicerTick;
    runUntil(metSeconds: number): State[];
}
