/**
 * Attitude Control (DAP) — RECONSTRUCTED from P-AXIS/Q-R-AXIS + TJET_LAW
 * DOCUMENTED deadbands 0.3deg, rate 0.3deg/s
 */
export interface Attitude { roll:number; pitch:number; yaw:number; rate:[number,number,number]; }
export const DEADBAND_DEG=0.3, RATE_DEADBAND_DPS=0.3;

export function dapStep(current:Attitude, desired:Attitude, dt:number): {jets:string[], gimbal:[number,number]} {
  // PD with deadband — RECONSTRUCTED simplification of phase-plane
  const errP = desired.pitch - current.pitch;
  const errR = desired.roll - current.roll;
  const errY = desired.yaw - current.yaw;
  const jets:string[]=[];
  if (Math.abs(errP)>DEADBAND_DEG || Math.abs(current.rate[1])>RATE_DEADBAND_DPS) jets.push(errP>0?"P+":"P-");
  if (Math.abs(errR)>DEADBAND_DEG) jets.push(errR>0?"R+":"R-");
  if (Math.abs(errY)>DEADBAND_DEG) jets.push(errY>0?"Y+":"Y-");
  // gimbal trim — DOCUMENTED TRIM_GIMBAL_CONTROL_SYSTEM 1472-1484
  const gimbal:[number,number]=[errP*0.01, errY*0.01];
  return { jets, gimbal };
}

/** Gimbal lock avoidance — DOCUMENTED GIMBAL_LOCK_AVOIDANCE 364 */
export function checkGimbalLock(cduMiddleDeg:number): boolean {
  return Math.abs(cduMiddleDeg) > 85; // DOCUMENTED threshold ~85°
}
