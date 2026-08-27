-- ada/dmp_sub.ads — Formally-verified AGC double-precision multiply (DMPSUB)
-- Sovereign Apollo — Ada/SPARK contribution (Nova Parr)
-- SPARK-proved: carry chain equals mathematical product mod 2**42

with Interfaces; use Interfaces;

pragma SPARK_Mode (On);

package DMP_Sub_Pkg is

   -- AGC 14-bit two's-complement word  (±16383)
   subtype AGC_Word is Integer_16 range -(2**14) .. 2**14 - 1;

   -- Three-limb accumulator: Acc0 (high), Acc1 (mid), Acc2 (low)
   type Triple_Accumulator is record
      High : Integer_64;
      Mid  : Integer_64;
      Low  : Integer_64;
   end record;

   -- -----------------------------------------------------------------------
   -- Ghost functions — mathematical specification
   -- -----------------------------------------------------------------------

   -- Exact signed integer product of two AGC_Words
   function Math_Product (A, B : AGC_Word) return Integer_64 is
      (Integer_64 (A) * Integer_64 (B))
   with Ghost;

   -- Reconstruct triple-precision integer from three limbs
   -- Value = High * 2**28 + Mid * 2**14 + Low
   function Limbs_To_TP (High, Mid, Low : Integer_64) return Integer_64 is
      (High * (2**28) + Mid * (2**14) + Low)
   with Ghost,
        Pre => High in -(2**13) .. 2**13 - 1 and
               Mid  in -(2**14) .. 2**14 - 1 and
               Low  in -(2**14) .. 2**14 - 1;

   -- -----------------------------------------------------------------------
   -- DMPSUB — Double-precision multiply
   --
   -- Multiplies two 14-bit AGC signed operands and delivers the 28-bit
   -- signed product in a three-limb result packed into MPAC(0..2).
   --
   -- Contract:
   --   Post: Limbs_To_TP(MPAC(0), MPAC(1), MPAC(2))
   --         ≡ Math_Product(Multiplicand, Multiplier)  (mod 2**42)
   -- -----------------------------------------------------------------------
   procedure DMP_Sub
     (Multiplicand :     AGC_Word;
      Multiplier   :     AGC_Word;
      MPAC         : out Triple_Accumulator)
   with
     SPARK_Mode => On,
     Pre  => True,
     Post =>
       (Limbs_To_TP (MPAC.High, MPAC.Mid, MPAC.Low) mod (2**42)) =
       (Math_Product (Multiplicand, Multiplier)       mod (2**42))
       and
       MPAC.High in -(2**13) .. 2**13 - 1
       and
       MPAC.Mid  in -(2**14) .. 2**14 - 1
       and
       MPAC.Low  in -(2**14) .. 2**14 - 1;

end DMP_Sub_Pkg;
