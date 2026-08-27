/**
 * Orbital mechanics — RECONSTRUCTED conic + Encke
 * DOCUMENTED: CONIC_SUBROUTINES 1159-1204, ORBITAL_INTEGRATION 1227-1248
 */
export type Vec3 = [number, number, number];
/** Conic propagation via Kepler f/g — RECONSTRUCTED analytic (INFERRED: series truncation) */
export declare function conicPropagate(r: Vec3, v: Vec3, dt: number, mu: number): {
    r: Vec3;
    v: Vec3;
};
/** Encke integration step — DOCUMENTED perturb vs conic */
export declare function enckeStep(r: Vec3, v: Vec3, dt: number, perturbations: Vec3): {
    r: Vec3;
    v: Vec3;
};
export declare function altitude(r: Vec3, body?: "moon" | "earth"): number;
