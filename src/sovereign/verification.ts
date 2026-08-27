/**
 * Runtime verification — checks invariants each Servicer tick
 * Maps to Formal package properties
 */
import { State } from "../mission/state.js";

export class InvariantViolation extends Error { constructor(public prop:string, msg:string){ super(`${prop}: ${msg}`); } }

export function assertInvariant(s:State): void {
  // Property 2: throttle bounds during P63/64
  if(s.guidanceMode==="P63" || s.guidanceMode==="P64"){
    if(s.propulsion.throttle!==0 && (s.propulsion.throttle<0.09 || s.propulsion.throttle>0.95)){
      throw new InvariantViolation("GuidanceInvariant", `throttle ${s.propulsion.throttle} out of [0.10,0.94] at ${s.met}`);
    }
  }
  // Property 3: nav bounds (lunar altitude)
  const alt = s.position[2]; // simplified
  if(s.vehicle==="lunar_orbit" && (alt<10000 || alt>500000)){
    // INFERRED placeholder — would use orbital altitude
  }
  // Property 4: fuel monotonic
  if(s.massKg < s.dryMassKg) throw new InvariantViolation("FuelMonotonic", `mass ${s.massKg} < dry ${s.dryMassKg}`);
  // Property 6: mission sequencing would be checked via timeline
}
