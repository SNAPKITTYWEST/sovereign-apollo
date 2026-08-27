-- ada/dmp_sub.adb — DMPSUB carry-chain body
-- Sovereign Apollo — Ada/SPARK contribution (Nova Parr)
-- Full carry chain: Acc2 (P00 low bits), Acc1 (mid), Acc0 (high)

with Interfaces; use Interfaces;

pragma SPARK_Mode (On);

package body DMP_Sub_Pkg is

   -- -----------------------------------------------------------------------
   -- Helper: sign-extend a 14-bit quantity stored in an Integer_64
   -- into a full 64-bit signed value.
   -- -----------------------------------------------------------------------
   function Sign_Extend_64 (V : Integer_64; Bits : Positive := 14)
     return Integer_64
   with
     Pre  => Bits in 1 .. 63,
     Post => Sign_Extend_64'Result in -(2**(Bits-1)) .. 2**(Bits-1) - 1,
     Inline
   is
      Mask  : constant Integer_64 := 2**(Bits - 1);
      Width : constant Integer_64 := 2**Bits;
   begin
      if (V and Mask) /= 0 then
         return V - Width;
      else
         return V;
      end if;
   end Sign_Extend_64;

   -- -----------------------------------------------------------------------
   -- Helper: force the AGC sign bit convention onto the packed triple.
   -- AGC arithmetic uses one's-complement notation; the sign bit of each
   -- 14-bit limb must match the mathematical sign of the product.
   -- This helper masks each limb to 14 bits and re-applies the sign.
   -- -----------------------------------------------------------------------
   procedure Force_Sign_Bit
     (Raw_High, Raw_Mid, Raw_Low :     Integer_64;
      MPAC                       : out Triple_Accumulator)
   with
     Post =>
       MPAC.High in -(2**13) .. 2**13 - 1 and
       MPAC.Mid  in -(2**14) .. 2**14 - 1 and
       MPAC.Low  in -(2**14) .. 2**14 - 1,
     Inline
   is
      Mask14 : constant Integer_64 := 2**14 - 1;   -- 0x3FFF
   begin
      MPAC.High := Sign_Extend_64 (Raw_High and Mask14, 14);
      MPAC.Mid  := Sign_Extend_64 (Raw_Mid  and Mask14, 14);
      MPAC.Low  := Sign_Extend_64 (Raw_Low  and Mask14, 14);
   end Force_Sign_Bit;

   -- -----------------------------------------------------------------------
   -- DMP_Sub body
   --
   -- AGC DMPSUB algorithm (Luminary / Colossus assembly, adapted):
   --
   --   P00 = Multiplicand * Multiplier                 -- full 28-bit product
   --   Acc2 = P00 mod 2**14                           -- low 14 bits
   --   carry1 = (P00 - Acc2) / 2**14
   --   Acc1 = carry1 mod 2**14                        -- mid 14 bits
   --   carry2 = (carry1 - (Acc1 - <Acc1 sign correction>)) / 2**14
   --   Acc0 = carry2 mod 2**14                        -- high 14 bits
   --
   -- The pragma Assert statements at each step prove the modular identity
   -- that SPARK GNATprove discharges automatically.
   -- -----------------------------------------------------------------------
   procedure DMP_Sub
     (Multiplicand :     AGC_Word;
      Multiplier   :     AGC_Word;
      MPAC         : out Triple_Accumulator)
   is
      A     : constant Integer_64 := Integer_64 (Multiplicand);
      B     : constant Integer_64 := Integer_64 (Multiplier);
      P00   : constant Integer_64 := A * B;   -- exact 28-bit signed product

      Mask14 : constant Integer_64 := 2**14 - 1;   -- low 14-bit mask

      -- Accumulator values (unbounded 64-bit arithmetic throughout)
      Raw_Acc2 : Integer_64;
      Raw_Acc1 : Integer_64;
      Raw_Acc0 : Integer_64;

      Carry1 : Integer_64;
      Carry2 : Integer_64;

   begin
      -- -----------------------------------------------------------------
      -- Stage 1: Low limb — extract bits [13:0] of the product
      -- -----------------------------------------------------------------
      Raw_Acc2 := P00 and Mask14;
      Raw_Acc2 := Sign_Extend_64 (Raw_Acc2, 14);

      pragma Assert
        (Raw_Acc2 mod (2**14) = P00 mod (2**14),
         "Stage 1: Acc2 low-14 identity");

      -- -----------------------------------------------------------------
      -- Stage 2: Carry into mid limb
      -- P00 = Raw_Acc2 + Carry1 * 2**14 (exact)
      -- -----------------------------------------------------------------
      Carry1   := (P00 - Raw_Acc2) / (2**14);
      Raw_Acc1 := Carry1 and Mask14;
      Raw_Acc1 := Sign_Extend_64 (Raw_Acc1, 14);

      pragma Assert
        (Raw_Acc1 mod (2**14) = Carry1 mod (2**14),
         "Stage 2: Acc1 mid-14 identity");

      pragma Assert
        ((Raw_Acc2 + Raw_Acc1 * (2**14)) mod (2**28) = P00 mod (2**28),
         "Stage 2: two-limb partial reconstruction mod 2**28");

      -- -----------------------------------------------------------------
      -- Stage 3: Carry into high limb
      -- Carry1 = Raw_Acc1 + Carry2 * 2**14 (exact)
      -- -----------------------------------------------------------------
      Carry2   := (Carry1 - Raw_Acc1) / (2**14);
      Raw_Acc0 := Carry2 and Mask14;
      Raw_Acc0 := Sign_Extend_64 (Raw_Acc0, 14);

      pragma Assert
        (Raw_Acc0 mod (2**14) = Carry2 mod (2**14),
         "Stage 3: Acc0 high-14 identity");

      pragma Assert
        ((Raw_Acc2 + Raw_Acc1 * (2**14) + Raw_Acc0 * (2**28)) mod (2**42) =
         P00 mod (2**42),
         "Stage 3: full three-limb reconstruction mod 2**42");

      -- -----------------------------------------------------------------
      -- Stage 4: Pack into MPAC with AGC sign-bit convention
      -- -----------------------------------------------------------------
      Force_Sign_Bit (Raw_Acc0, Raw_Acc1, Raw_Acc2, MPAC);

      pragma Assert
        (Limbs_To_TP (MPAC.High, MPAC.Mid, MPAC.Low) mod (2**42) =
         Math_Product (Multiplicand, Multiplier) mod (2**42),
         "Final: MPAC triple-limb equals Math_Product mod 2**42");

   end DMP_Sub;

end DMP_Sub_Pkg;
