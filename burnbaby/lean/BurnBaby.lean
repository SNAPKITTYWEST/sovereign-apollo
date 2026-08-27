-- BurnBaby.lean  — Formal verification of AGC ignition safety invariants
-- These are the only zero-sorry proofs in the Sovereign Apollo body of work.
--
-- The two theorems jointly prove that thrust is gated by BOTH temporal
-- constraints (TGO ≤ 0) AND explicit crew consent (AstronautGo = true),
-- matching the AGC's IGNYET? check that prevented accidental ignition.
--
-- Requires: Mathlib (lake add mathlib)
-- Build:    lake build

import Mathlib.Tactic

namespace AgcIgnition

-- The two discrete engine states (maps to ENGONFLG in AGC erasable memory)
inductive EngineState
  | Idle
  | Thrust
deriving DecidableEq, Repr

-- Mission state at TIG-0 evaluation
structure IgnitionContext where
  TGO          : ℤ    -- Time To Go (centiseconds); negative = past TIG
  AstronautGo  : Bool  -- ASTNFLAG: set by Verb 99 PROCEED from crew
  UllageSettled: Bool  -- Physical propellant settled (from ullage motors)

-- The BURNBABY transition function: thrust iff all three gates pass.
-- Directly models the IF / CCS / BZF chain in the AGC listing.
def evaluate_ignition (ctx : IgnitionContext) : EngineState :=
  if ctx.TGO ≤ 0 ∧ ctx.AstronautGo ∧ ctx.UllageSettled then
    EngineState.Thrust
  else
    EngineState.Idle

-- ─────────────────────────────────────────────────────────────────────────
-- THEOREM 1: Absolute Crew Consent Gate
-- Thrust cannot occur unless the astronaut has explicitly pressed PROCEED
-- (V99NXX), regardless of how much time has elapsed.
-- ─────────────────────────────────────────────────────────────────────────
theorem thrust_requires_astronaut (ctx : IgnitionContext) :
    evaluate_ignition ctx = EngineState.Thrust → ctx.AstronautGo = true := by
  intro h
  dsimp [evaluate_ignition] at h
  split at h
  · rename_i h_cond
    exact h_cond.2.1
  · contradiction

-- ─────────────────────────────────────────────────────────────────────────
-- THEOREM 2: Temporal Strictness
-- Thrust cannot occur before TIG-0 (TGO must be ≤ 0).
-- ─────────────────────────────────────────────────────────────────────────
theorem thrust_at_tig_zero (ctx : IgnitionContext) :
    evaluate_ignition ctx = EngineState.Thrust → ctx.TGO ≤ 0 := by
  intro h
  dsimp [evaluate_ignition] at h
  split at h
  · rename_i h_cond
    exact h_cond.1
  · contradiction

-- ─────────────────────────────────────────────────────────────────────────
-- COROLLARY: Both gates required simultaneously.
-- Convenience lemma combining the two theorems.
-- ─────────────────────────────────────────────────────────────────────────
theorem thrust_requires_both_gates (ctx : IgnitionContext) :
    evaluate_ignition ctx = EngineState.Thrust →
    ctx.TGO ≤ 0 ∧ ctx.AstronautGo = true := by
  intro h
  exact ⟨thrust_at_tig_zero ctx h, thrust_requires_astronaut ctx h⟩

end AgcIgnition
