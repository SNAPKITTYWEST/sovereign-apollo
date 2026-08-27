/**
 * Vehicle State + Mission Phase — normalized schema
 */
export type GuidanceMode = "IU" | "PGNCS" | "P00" | "P12" | "P20" | "P30" | "P40" | "P63" | "P64" | "P66" | "P68" | "P12_ASCENT" | "IDLE";
export type VehicleState = "stack_thrusting" | "LEO" | "TLI" | "coast" | "lunar_orbit" | "PDI" | "surface" | "ascent" | "docked" | "TEI" | "reentry";
export type CommsState = "MSFN" | "LOS" | "VHF" | "S_BAND";
export interface PropulsionState {
    engine: string;
    thrustN: number;
    ispS: number;
    throttle: number;
    engOn: boolean;
}
export interface State {
    metSeconds: number;
    met: string;
    vehicle: VehicleState;
    guidanceMode: GuidanceMode;
    propulsion: PropulsionState;
    comms: CommsState;
    position: [number, number, number];
    velocity: [number, number, number];
    massKg: number;
    dryMassKg: number;
    cdu: [number, number, number];
    alarm?: string;
    phaseTable?: number;
}
export declare function metToString(s: number): string;
export declare function stringToMet(s: string): number;
