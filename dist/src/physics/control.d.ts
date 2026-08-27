/**
 * Attitude Control (DAP) — RECONSTRUCTED from P-AXIS/Q-R-AXIS + TJET_LAW
 * DOCUMENTED deadbands 0.3deg, rate 0.3deg/s
 */
export interface Attitude {
    roll: number;
    pitch: number;
    yaw: number;
    rate: [number, number, number];
}
export declare const DEADBAND_DEG = 0.3, RATE_DEADBAND_DPS = 0.3;
export declare function dapStep(current: Attitude, desired: Attitude, dt: number): {
    jets: string[];
    gimbal: [number, number];
};
/** Gimbal lock avoidance — DOCUMENTED GIMBAL_LOCK_AVOIDANCE 364 */
export declare function checkGimbalLock(cduMiddleDeg: number): boolean;
