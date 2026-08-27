/**
 * Saturn V — DOCUMENTED from MSFC-MAN-507
 */
export interface StageSpec {
    name: string;
    engines: string;
    thrustSeaN: number;
    thrustVacN: number;
    propKg: number;
    burnS: number;
    isp: number;
}
export declare const SATURN_V: StageSpec[];
export declare function stageDeltaV(spec: StageSpec, m0: number, mf: number): number;
