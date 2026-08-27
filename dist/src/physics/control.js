export const DEADBAND_DEG = 0.3, RATE_DEADBAND_DPS = 0.3;
export function dapStep(current, desired, dt) {
    // PD with deadband — RECONSTRUCTED simplification of phase-plane
    const errP = desired.pitch - current.pitch;
    const errR = desired.roll - current.roll;
    const errY = desired.yaw - current.yaw;
    const jets = [];
    if (Math.abs(errP) > DEADBAND_DEG || Math.abs(current.rate[1]) > RATE_DEADBAND_DPS)
        jets.push(errP > 0 ? "P+" : "P-");
    if (Math.abs(errR) > DEADBAND_DEG)
        jets.push(errR > 0 ? "R+" : "R-");
    if (Math.abs(errY) > DEADBAND_DEG)
        jets.push(errY > 0 ? "Y+" : "Y-");
    // gimbal trim — DOCUMENTED TRIM_GIMBAL_CONTROL_SYSTEM 1472-1484
    const gimbal = [errP * 0.01, errY * 0.01];
    return { jets, gimbal };
}
/** Gimbal lock avoidance — DOCUMENTED GIMBAL_LOCK_AVOIDANCE 364 */
export function checkGimbalLock(cduMiddleDeg) {
    return Math.abs(cduMiddleDeg) > 85; // DOCUMENTED threshold ~85°
}
//# sourceMappingURL=control.js.map