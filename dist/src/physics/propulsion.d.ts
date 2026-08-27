/**
 * Propulsion — DOCUMENTED tables + THROTTLE_CONTROL_ROUTINES 793-797
 */
export interface EngineSpec {
    name: string;
    thrustN: number;
    ispS: number;
    throttleMin: number;
    throttleMax: number;
}
export declare const ENGINES: Record<string, EngineSpec>;
/** THROTTLE_CONTROL logic — DOCUMENTED pp.793-797 */
export declare function throttleCommand(aCmd: number, fc: number, mass: number): number;
export declare function massFlow(thrust: number, isp: number): number;
