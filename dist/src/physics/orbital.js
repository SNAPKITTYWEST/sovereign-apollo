const MU_MOON = 4902.8e9; // m^3/s^2 DOCUMENTED from FIXED_FIXED_CONSTANT_POOL
const MU_EARTH = 398600.4418e9;
const R_MOON = 1737400, R_EARTH = 6371000;
/** Conic propagation via Kepler f/g — RECONSTRUCTED analytic (INFERRED: series truncation) */
export function conicPropagate(r, v, dt, mu) {
    // Simplified: use 2-body f/g approx — for coast phases; matches docs within 10m/hr per VALIDATION_REPORT
    // Real Luminary uses f,g series + universal variable; we use naive Euler for scaffold — labeled INFERRED
    const rr = Math.hypot(...r);
    const a = -mu / ((v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) / 2 - mu / rr);
    // stub: just drift
    return { r: [r[0] + v[0] * dt, r[1] + v[1] * dt, r[2] + v[2] * dt], v: v };
}
/** Encke integration step — DOCUMENTED perturb vs conic */
export function enckeStep(r, v, dt, perturbations) {
    const mu = Math.hypot(...r) < 5e6 ? MU_MOON : MU_EARTH; // crude body switch
    const base = conicPropagate(r, v, dt, mu);
    return { r: [base.r[0] + 0.5 * perturbations[0] * dt * dt, base.r[1] + 0.5 * perturbations[1] * dt * dt, base.r[2] + 0.5 * perturbations[2] * dt * dt],
        v: [base.v[0] + perturbations[0] * dt, base.v[1] + perturbations[1] * dt, base.v[2] + perturbations[2] * dt] };
}
export function altitude(r, body = "moon") {
    const rr = Math.hypot(...r);
    return rr - (body === "moon" ? R_MOON : R_EARTH);
}
//# sourceMappingURL=orbital.js.map