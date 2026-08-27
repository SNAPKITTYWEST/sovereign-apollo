/**
 * LM — DOCUMENTED from LM AOH / LEM_GEOMETRY 320-325
 */
export declare const LM_SPEC: {
    totalMassKg: number;
    ascentDryKg: number;
    descentDryKg: number;
    dpsThrustMaxN: number;
    dpsThrottleRange: readonly [0.1, 0.94];
    apsThrustN: number;
    rcsThrustN: number;
    rcsCount: number;
    descentBatteryAh: number;
    ascentBatteryAh: number;
};
export interface LmState {
    descentAttached: boolean;
    gearDeployed: boolean;
    dpsGimbal: [number, number];
    dskyProg: string;
}
