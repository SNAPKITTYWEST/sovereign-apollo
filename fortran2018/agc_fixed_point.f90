! agc_fixed_point.f90 — 15-bit 1's complement fixed-point ALU
! Author: Kimi (Moonshot AI) + Nova Parr (GPT)
! Part of the Fortran 2018 clean-room AGC interpreter.
!
! Key design: cleanly distinguishes encoded AGC words (stored 15-bit
! 1's complement) from signed host integers.  Preserves +0 / -0.
! End-Around Carry (EAC) is explicit and double-folded.

module agc_fixed_point
  use agc_assembly_symbols
  implicit none
  private

  public :: ones_comp_normalize, ones_comp_negate, is_negative, is_minus_zero
  public :: ones_comp_add, ones_comp_add_n, ones_comp_sub
  public :: agc_sign_extend, agc_word_to_int, agc_int_to_word
  public :: agc_dp_pack, agc_dp_unpack, agc_dp_to_int
  public :: agc_shift_right_rne, agc_q28_to_q14_rne, agc_round_dp_rne
  public :: agc_fixed_to_float, agc_float_to_fixed

contains

  ! ==========================================================================
  ! Core 1's complement primitives
  ! ==========================================================================

  pure function ones_comp_normalize(word) result(norm)
    integer(INT64_KIND), intent(in) :: word
    integer(INT64_KIND) :: norm
    norm = iand(word, AGC_WORD_MASK)
  end function ones_comp_normalize

  pure function ones_comp_negate(word) result(neg)
    integer(INT64_KIND), intent(in) :: word
    integer(INT64_KIND) :: neg
    neg = ieor(ones_comp_normalize(word), AGC_WORD_MASK)
  end function ones_comp_negate

  pure function is_negative(word) result(negative)
    integer(INT64_KIND), intent(in) :: word
    logical :: negative
    negative = iand(ones_comp_normalize(word), AGC_SIGN_BIT) /= 0_INT64_KIND
  end function is_negative

  pure function is_minus_zero(word) result(mz)
    integer(INT64_KIND), intent(in) :: word
    logical :: mz
    mz = ones_comp_normalize(word) == AGC_MINUS_ZERO
  end function is_minus_zero

  ! ==========================================================================
  ! 1's complement addition with End-Around Carry (EAC)
  ! Add the operands as unsigned bit patterns, mask to 15 bits, then fold
  ! any carry-out back into bit 0.  Double-fold handles the rare carry-from-EAC.
  ! ==========================================================================

  pure function ones_comp_add(a, b) result(sum)
    integer(INT64_KIND), intent(in) :: a, b
    integer(INT64_KIND) :: sum, raw
    raw = iand(a, AGC_WORD_MASK) + iand(b, AGC_WORD_MASK)
    raw = iand(raw, AGC_WORD_MASK) + ishft(raw, -15)   ! fold carry out of bit 14
    raw = iand(raw, AGC_WORD_MASK) + ishft(raw, -15)   ! fold once more (rare)
    sum = iand(raw, AGC_WORD_MASK)
  end function ones_comp_add

  ! Generic N-bit version (2 <= nbits <= 62)
  pure function ones_comp_add_n(a, b, nbits) result(sum)
    integer(INT64_KIND), intent(in) :: a, b
    integer, intent(in) :: nbits
    integer(INT64_KIND) :: sum, mask, raw
    if (nbits < 2 .or. nbits > 62) then
      sum = 0_INT64_KIND ; return
    end if
    mask = ishft(1_INT64_KIND, nbits) - 1_INT64_KIND
    raw  = iand(a, mask) + iand(b, mask)
    raw  = iand(raw, mask) + ishft(raw, -nbits)
    raw  = iand(raw, mask) + ishft(raw, -nbits)
    sum  = iand(raw, mask)
  end function ones_comp_add_n

  ! Subtraction via complement + add
  pure function ones_comp_sub(a, b) result(difference)
    integer(INT64_KIND), intent(in) :: a, b
    integer(INT64_KIND) :: difference
    difference = ones_comp_add(a, ones_comp_negate(b))
  end function ones_comp_sub

  ! ==========================================================================
  ! Sign extension and integer conversion
  ! ==========================================================================

  pure function agc_sign_extend(word) result(value)
    integer(INT64_KIND), intent(in) :: word
    integer(INT64_KIND) :: value
    value = iand(word, AGC_WORD_MASK)
    if (iand(value, AGC_SIGN_BIT) /= 0_INT64_KIND) then
      value = value - AGC_WORD_MASK - 1_INT64_KIND   ! map to signed range
    end if
  end function agc_sign_extend

  pure function agc_word_to_int(word) result(value)
    integer(INT64_KIND), intent(in) :: word
    integer(INT64_KIND) :: value
    value = agc_sign_extend(word)
    if (is_negative(word)) value = -iand(ieor(word, AGC_WORD_MASK), AGC_MAG_MASK)
  end function agc_word_to_int

  pure function agc_int_to_word(value) result(word)
    integer(INT64_KIND), intent(in) :: value
    integer(INT64_KIND) :: word
    if (value >= 0_INT64_KIND) then
      word = iand(value, AGC_MAG_MASK)
    else
      word = ior(iand(-value, AGC_MAG_MASK), AGC_SIGN_BIT)
    end if
  end function agc_int_to_word

  ! ==========================================================================
  ! Double-precision (28-bit) packing
  ! ==========================================================================

  pure function agc_dp_pack(hi, lo) result(dp)
    integer(INT64_KIND), intent(in) :: hi, lo
    integer(INT64_KIND) :: dp
    dp = ior(ishft(iand(hi, AGC_WORD_MASK), 14), iand(lo, int(z'3FFF', INT64_KIND)))
  end function agc_dp_pack

  pure subroutine agc_dp_unpack(dp, hi, lo)
    integer(INT64_KIND), intent(in)  :: dp
    integer(INT64_KIND), intent(out) :: hi, lo
    integer(INT64_KIND) :: sign_bit
    hi = iand(ishft(dp, -14), AGC_WORD_MASK)
    lo = iand(dp, int(z'3FFF', INT64_KIND))
    sign_bit = iand(hi, int(z'4000', INT64_KIND))
    lo = ior(lo, sign_bit)
  end subroutine agc_dp_unpack

  pure function agc_dp_to_int(dp_value) result(value)
    integer(INT64_KIND), intent(in) :: dp_value(2)
    integer(INT64_KIND) :: value
    value = agc_dp_pack(dp_value(1), dp_value(2))
    if (iand(value, AGC_DP_SIGN) /= 0_INT64_KIND) then
      value = -(iand(ieor(value, int(z'1FFFFFFF', INT64_KIND)), AGC_DP_MASK))
    end if
  end function agc_dp_to_int

  ! ==========================================================================
  ! Round-to-nearest-even shift (DP → SP downscaling)
  ! Optimized: uses ibits() to extract discarded bits, avoids variable masks.
  ! ==========================================================================

  pure elemental function agc_shift_right_rne(value, shift) result(rounded)
    integer(INT64_KIND), intent(in) :: value
    integer, intent(in) :: shift
    integer(INT64_KIND) :: rounded, magnitude, quotient, remainder, half
    logical :: negative

    if (shift <= 0) then
      rounded = ishft(value, -shift) ; return
    end if
    if (shift >= 62 .or. value == 0_INT64_KIND) then
      rounded = 0_INT64_KIND ; return
    end if

    negative = value < 0_INT64_KIND
    magnitude = merge(-value, value, negative)
    quotient  = ishft(magnitude, -shift)
    remainder = ibits(magnitude, 0, shift)
    half      = ishft(1_INT64_KIND, shift - 1)

    if (remainder > half .or. &
        (remainder == half .and. iand(quotient, 1_INT64_KIND) /= 0_INT64_KIND)) then
      quotient = quotient + 1_INT64_KIND
    end if
    rounded = merge(-quotient, quotient, negative)
  end function agc_shift_right_rne

  ! Specialised Q1.28 → Q1.14 (constant-fold-friendly)
  pure elemental function agc_q28_to_q14_rne(value) result(rounded)
    integer(INT64_KIND), intent(in) :: value
    integer(INT64_KIND) :: rounded, magnitude, quotient, remainder
    logical :: negative

    if (value == 0_INT64_KIND) then
      rounded = 0_INT64_KIND ; return
    end if
    negative  = value < 0_INT64_KIND
    magnitude = merge(-value, value, negative)
    quotient  = ishft(magnitude, -14)
    remainder = iand(magnitude, int(z'3FFF', INT64_KIND))

    if (remainder > 8192_INT64_KIND .or. &
        (remainder == 8192_INT64_KIND .and. &
         iand(quotient, 1_INT64_KIND) /= 0_INT64_KIND)) then
      quotient = quotient + 1_INT64_KIND
    end if
    rounded = merge(-quotient, quotient, negative)
  end function agc_q28_to_q14_rne

  pure function agc_round_dp_rne(dp_value) result(sp_value)
    integer(INT64_KIND), intent(in) :: dp_value(2)
    integer(INT64_KIND) :: sp_value
    sp_value = agc_int_to_word(agc_q28_to_q14_rne(agc_dp_to_int(dp_value)))
  end function agc_round_dp_rne

  ! ==========================================================================
  ! Float conversion helpers (for trig / reference use only)
  ! ==========================================================================

  pure function agc_fixed_to_float(word, scale) result(flt)
    integer(INT64_KIND), intent(in) :: word
    integer, intent(in) :: scale
    real :: flt
    flt = real(agc_word_to_int(word)) / real(ishft(1_INT64_KIND, scale))
  end function agc_fixed_to_float

  pure function agc_float_to_fixed(flt, scale) result(word)
    real, intent(in) :: flt
    integer, intent(in) :: scale
    integer(INT64_KIND) :: word
    word = agc_int_to_word(int(flt * real(ishft(1_INT64_KIND, scale)), INT64_KIND))
  end function agc_float_to_fixed

end module agc_fixed_point
