/**
 * Saturn V — DOCUMENTED from MSFC-MAN-507
 */
export interface StageSpec { name:string; engines:string; thrustSeaN:number; thrustVacN:number; propKg:number; burnS:number; isp:number; }
export const SATURN_V: StageSpec[] = [
  { name:"S-IC", engines:"5xF-1", thrustSeaN:33.4e6, thrustVacN:39e6, propKg:2_039_000, burnS:168, isp:263 },
  { name:"S-II", engines:"5xJ-2", thrustSeaN:0, thrustVacN:5.03e6, propKg:480_000, burnS:360, isp:421 },
  { name:"S-IVB", engines:"1xJ-2", thrustSeaN:0, thrustVacN:1.033e6, propKg:119_000, burnS:165, isp:421 }, // first burn
];
export function stageDeltaV(spec:StageSpec, m0:number, mf:number): number {
  return spec.isp*9.80665*Math.log(m0/mf);
}
