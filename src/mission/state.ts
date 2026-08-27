/**
 * Vehicle State + Mission Phase — normalized schema
 */
export type GuidanceMode = "IU"|"PGNCS"|"P00"|"P12"|"P20"|"P30"|"P40"|"P63"|"P64"|"P66"|"P68"|"P12_ASCENT"|"IDLE";
export type VehicleState = "stack_thrusting"|"LEO"|"TLI"|"coast"|"lunar_orbit"|"PDI"|"surface"|"ascent"|"docked"|"TEI"|"reentry";
export type CommsState = "MSFN"|"LOS"|"VHF"|"S_BAND";

export interface PropulsionState {
  engine: string; thrustN:number; ispS:number; throttle:number; engOn:boolean;
}
export interface State {
  metSeconds:number;
  met:string; // 000:00:00
  vehicle: VehicleState;
  guidanceMode: GuidanceMode;
  propulsion: PropulsionState;
  comms: CommsState;
  position: [number,number,number]; // m ECI or LCL
  velocity: [number,number,number];
  massKg:number; dryMassKg:number;
  cdu: [number,number,number]; // deg
  alarm?: string; // 1202 etc
  phaseTable?: number;
}

export function metToString(s:number): string {
  const h=Math.floor(s/3600), m=Math.floor((s%3600)/60), sec=s%60;
  return `${String(h).padStart(3,"0")}:${String(m).padStart(2,"0")}:${String(sec).padStart(2,"0")}`;
}
export function stringToMet(s:string): number {
  const [h,m,sec]=s.split(":").map(Number); return h*3600+m*60+sec;
}
