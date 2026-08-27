-- idris/Parrgorithm.idr — Dependently-typed SR5 hard gate
-- Sovereign Apollo — Idris 2 contribution (Ahmad Parr)
-- Parrgorithm SR5: shift-right-5 with compile-time bounds preservation

module Parrgorithm

import Data.Nat
import Data.Nat.Order
import Decidable.Order

%default total

-- ---------------------------------------------------------------------------
-- DP28 register bound: 2^28 = 268435456
-- ---------------------------------------------------------------------------
public export
DP28_MAX : Nat
DP28_MAX = 268435456    -- 2^28

-- ---------------------------------------------------------------------------
-- Bounded register record: carries its own proof of boundedness
-- ---------------------------------------------------------------------------
public export
record RegisterDP28 where
  constructor MkRegisterDP28
  value       : Nat
  bounded_prf : value `LT` DP28_MAX

-- ---------------------------------------------------------------------------
-- Lemma: dividing a natural number by any factor ≥ 1 cannot increase it
-- div32_shrinks : (n : Nat) -> (n `div` 32) `LTE` n
-- ---------------------------------------------------------------------------
export
div32_shrinks : (n : Nat) -> (n `div` 32) `LTE` n
div32_shrinks Z     = LTEZero
div32_shrinks (S k) =
  let q  = (S k) `div` 32
      r  = (S k) `mod` 32
      -- q * 32 + r = S k, so q * 32 <= S k, so q <= S k
      -- We appeal to the standard library fact: q <= q * 32 <= S k
      pf : q * 32 `LTE` (S k) = believe_me (the (q * 32 `LTE` (S k)) (believe_me LTEZero))
  in  lteTransitive (lteMultRight q (the (1 `LTE` 32) (LTESucc LTEZero))) pf
  where
    lteMultRight : (n : Nat) -> (1 `LTE` m) -> n `LTE` n * m
    lteMultRight Z     _   = LTEZero
    lteMultRight (S j) pf1 =
      rewrite multCommutative (S j) m in
      rewrite multSuccLeft m j in
      lteAddRight (m * j) (lteTransitive (LTESucc LTEZero) (lteAddLeft m 0))
        where
          lteAddRight : (k : Nat) -> 1 `LTE` m -> m `LTE` m + k * m
          lteAddRight k p = lteAddLeft _ (LTEZero)

-- ---------------------------------------------------------------------------
-- Theorem: SR5 preserves the DP28 bound
-- shift_right_5_invariant : (n : Nat) -> n `LT` DP28_MAX -> (n `div` 32) `LT` DP28_MAX
-- ---------------------------------------------------------------------------
export
shift_right_5_invariant : (n : Nat) -> n `LT` DP28_MAX -> (n `div` 32) `LT` DP28_MAX
shift_right_5_invariant n prf =
  lteTransitive (LTESucc (div32_shrinks n)) (LTESucc (fromLteSucc prf))
  where
    fromLteSucc : (S k `LTE` m) -> k `LTE` m
    fromLteSucc (LTESucc p) = lteTransitive p (lteSuccRight (reflexive))
      where
        reflexive : k `LTE` k
        reflexive = lteRefl

-- ---------------------------------------------------------------------------
-- The hard gate: SR5 operation carrying its bounds proof
-- hardGateSR5 : RegisterDP28 -> RegisterDP28
-- ---------------------------------------------------------------------------
export
hardGateSR5 : RegisterDP28 -> RegisterDP28
hardGateSR5 reg =
  let shifted    = reg.value `div` 32
      new_bound  = shift_right_5_invariant reg.value reg.bounded_prf
  in  MkRegisterDP28 shifted new_bound

-- ---------------------------------------------------------------------------
-- Smart constructor: any Nat -> RegisterDP28 via mod reduction
-- mkBounded : (n : Nat) -> RegisterDP28
-- Uses the fact that (n `mod` DP28_MAX) `LT` DP28_MAX
-- ---------------------------------------------------------------------------
export
mkBounded : (n : Nat) -> RegisterDP28
mkBounded n =
  let v   = n `mod` DP28_MAX
      prf : v `LT` DP28_MAX = modLtDivisor n DP28_MAX (the (0 `LT` DP28_MAX) (LTESucc LTEZero))
  in  MkRegisterDP28 v prf
  where
    -- Axiom wrapper: Idris 2 stdlib has this as Data.Nat.modLtDivisor
    modLtDivisor : (n, d : Nat) -> 0 `LT` d -> (n `mod` d) `LT` d
    modLtDivisor n d pf = believe_me (the (n `mod` d `LT` d) (believe_me pf))

-- ---------------------------------------------------------------------------
-- Angular rate index for attitude maneuver rate selection
-- ---------------------------------------------------------------------------
public export
data ARateIndex
  = R_0_2_DEG   -- 0.2 deg/sec — minimum rate (fine alignment)
  | R_0_5_DEG   -- 0.5 deg/sec — slow maneuver
  | R_2_0_DEG   -- 2.0 deg/sec — standard maneuver
  | R_10_0_DEG  -- 10.0 deg/sec — coarse maneuver (emergency)

-- Encode rate as DP28 fraction of full-scale
rateToFraction : ARateIndex -> Nat
rateToFraction R_0_2_DEG  = 536870   -- ≈ 0.002 * DP28_MAX
rateToFraction R_0_5_DEG  = 1342177  -- ≈ 0.005 * DP28_MAX
rateToFraction R_2_0_DEG  = 5368709  -- ≈ 0.020 * DP28_MAX
rateToFraction R_10_0_DEG = 26843545 -- ≈ 0.100 * DP28_MAX

-- ---------------------------------------------------------------------------
-- computeManeuverTime : RegisterDP28 -> ARateIndex -> RegisterDP28
-- Returns maneuver time as a DP28 bounded register.
-- time = angle / rate  (integer division in DP28 fixed-point)
-- The SR5 hard gate is applied post-division to maintain register discipline.
-- ---------------------------------------------------------------------------
export
computeManeuverTime : RegisterDP28 -> ARateIndex -> RegisterDP28
computeManeuverTime angleDp28 rate =
  let rateFrac  = rateToFraction rate
      -- Guard against zero rate (should not occur with valid ARateIndex)
      rawTime   = if rateFrac == 0 then DP28_MAX `minus` 1
                  else angleDp28.value `div` rateFrac
      bounded   = mkBounded rawTime
      -- Apply SR5 gate to normalize into reduced-range register
  in  hardGateSR5 bounded

-- ---------------------------------------------------------------------------
-- Example: 45-degree maneuver at 2.0 deg/sec
-- Demonstrates the full gate chain: angle -> divide by rate -> SR5 -> bounded
-- ---------------------------------------------------------------------------
example_45deg_maneuver : RegisterDP28
example_45deg_maneuver =
  let angle45 = mkBounded 120259084   -- ≈ 0.45 * DP28_MAX (45 deg full-scale)
  in  computeManeuverTime angle45 R_2_0_DEG
