/**
 * CSM — DOCUMENTED from AOH
 */
export declare const CSM_SPEC: {
    cmMassKg: number;
    smMassKg: number;
    propKg: number;
    spsThrustN: number;
    spsIsp: number;
    rcsThrustN: number;
    rcsCount: number;
    buses: readonly ["MAIN_A", "MAIN_B", "MAIN_C"];
};
export interface CsmState {
    cmAttached: boolean;
    smJettison: boolean;
    spsGimbal: [number, number];
}
