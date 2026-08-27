/-
  Sovereign Apollo — State + MET + Guidance Mode
  Evidence: TIMELINE-001, ERASABLE_ASSIGNMENTS, LUM099-001
-/

inductive GuidanceMode where
  | IU | P00 | P12 | P20 | P30 | P40 | P63 | P64 | P66 | P68 | IDLE
  deriving DecidableEq, Repr

inductive VehicleState where
  | StackThrusting | LEO | TLI | Coast | LunarOrbit | PDI | Surface | Ascent | Docked | TEI | Reentry
  deriving DecidableEq, Repr

structure State where
  metSeconds : Nat
  vehicle    : VehicleState
  guidance   : GuidanceMode
  massKg     : Nat
  dryMassKg  : Nat
  throttlePermille : Nat  -- 0..1000 (100 = 10%)
  deriving Repr

def State.throttleOk (s : State) : Prop :=
  (s.guidance = .P63 ∨ s.guidance = .P64) →
    (100 ≤ s.throttlePermille ∧ s.throttlePermille ≤ 940)

theorem fuel_nonnegative (s : State) (h : s.massKg ≥ s.dryMassKg) : s.massKg ≥ s.dryMassKg := h
