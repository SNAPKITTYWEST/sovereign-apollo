/**
 * Runtime verification — checks invariants each Servicer tick
 * Maps to Formal package properties
 */
import { State } from "../mission/state.js";
export declare class InvariantViolation extends Error {
    prop: string;
    constructor(prop: string, msg: string);
}
export declare function assertInvariant(s: State): void;
