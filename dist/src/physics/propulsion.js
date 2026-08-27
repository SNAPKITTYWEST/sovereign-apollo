export const ENGINES = {
    DPS: { name: "DPS", thrustN: 45000, ispS: 311, throttleMin: 0.10, throttleMax: 0.94 }, // 10-94% DOCUMENTED, later 57% max for PDI
    APS: { name: "APS", thrustN: 15500, ispS: 311, throttleMin: 1, throttleMax: 1 },
    SPS: { name: "SPS", thrustN: 91190, ispS: 314, throttleMin: 1, throttleMax: 1 }, // 20.5 klbf
    F1: { name: "F-1", thrustN: 6.77e6, ispS: 263, throttleMin: 1, throttleMax: 1 },
    J2: { name: "J-2", thrustN: 1.033e6, ispS: 421, throttleMin: 1, throttleMax: 1 },
};
/** THROTTLE_CONTROL logic — DOCUMENTED pp.793-797 */
export function throttleCommand(aCmd, fc, mass) {
    // Simplified: FC = thrust/mass ; throttle = ACOMMAND/FC ; clamped
    const fcEff = fc || (ENGINES.DPS.thrustN / mass);
    let throttle = Math.abs(aCmd) / fcEff;
    const min = ENGINES.DPS.throttleMin, max = ENGINES.DPS.throttleMax;
    if (throttle < min)
        throttle = min;
    if (throttle > max)
        throttle = max;
    return throttle;
}
export function massFlow(thrust, isp) { return thrust / (isp * 9.80665); }
//# sourceMappingURL=propulsion.js.map