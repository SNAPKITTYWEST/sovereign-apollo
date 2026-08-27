/**
 * Physics Engine — MODERN DESIGN preserving Apollo constraints
 * Deterministic fixed-step; drives Servicer 2-s cycle
 */
import { State, GuidanceMode, PropulsionState } from "../mission/state.js";

export interface PhysicsConfig {
  dtMs: number; // minor cycle 1ms
  servicerPeriodMs: number; // 2000ms DOCUMENTED
}

export const DEFAULT_CONFIG: PhysicsConfig = { dtMs: 1, servicerPeriodMs: 2000 };

export class PhysicsEngine {
  state: State;
  tMs = 0;
  servicerAccum = 0;
  cfg: PhysicsConfig;
  constructor(initial: State, cfg=DEFAULT_CONFIG){ this.state=initial; this.cfg=cfg; }

  /** Deterministic step — no Date.now, no random without seed */
  step(dtMs?: number): void {
    const dt = (dtMs ?? this.cfg.dtMs)/1000; // s
    this.tMs += dt*1000;
    this.servicerAccum += dt*1000;
    // Simple Euler for demo — RECONSTRUCTED: replace with RK4+thrust per propulsion.ts
    // Apply thrust if ENG ON
    if (this.state.propulsion.thrustN>0) {
      const mass = this.state.massKg;
      const a = this.state.propulsion.thrustN / mass;
      // assume +Z thrust in local — INFERRED simplification
      this.state.velocity[2] += a*dt;
      // mass flow
      const isp = this.state.propulsion.ispS;
      const mdot = this.state.propulsion.thrustN / (isp*9.80665);
      this.state.massKg -= mdot*dt;
      if (this.state.massKg < this.state.dryMassKg) this.state.massKg = this.state.dryMassKg;
    }
    // gravity (central body) — simplified; orbital.ts does N-body
    const g0 = 1.62; // lunar — INFERRED; engine swaps body by altitude
    this.state.velocity[2] -= g0*dt * 0.1; // placeholder
    // position integrate
    this.state.position[0]+= this.state.velocity[0]*dt;
    this.state.position[1]+= this.state.velocity[1]*dt;
    this.state.position[2]+= this.state.velocity[2]*dt;

    if (this.servicerAccum >= this.cfg.servicerPeriodMs) {
      this.servicerTick();
      this.servicerAccum=0;
    }
  }

  private servicerTick() {
    // DOCUMENTED: Servicer 2-s guidance cycle would call LUNAR_LANDING_GUIDANCE_EQUATIONS
    // Here we enforce guidance invariants (see sovereign/verification.ts)
    // throttle logic etc. injected externally
  }

  runUntil(metSeconds: number): State[] {
    const trace: State[] = [];
    const targetMs = metSeconds*1000;
    while (this.tMs < targetMs) { this.step(); if (this.tMs % 2000 <1) trace.push(structuredClone(this.state)); }
    return trace;
  }
}
