! agc_alu_parity.f90 — Sovereign AGC 15-bit / 28-bit 1's Complement ALU
! Target: Bit-Exact Parity with Apollo Guidance Computer Fixed-Point Math
!
! Key: AGC used 1's complement with End-Around Carry (EAC) and distinct
! +0 (00000) / -0 (77777) representations.  DP = 2 x 15-bit words packed
! into 29-bit signed integer (1 sign + 28 magnitude bits).
!
! Compile as module: gfortran -std=f2008 -c agc_alu_parity.f90

module agc_alu_parity
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
  private

  integer(int32), parameter :: MASK_14 = int(Z'00003FFF', int32) ! 14-bit magnitude
  integer(int32), parameter :: MASK_15 = int(Z'00007FFF', int32) ! 15-bit SP word
  integer(int32), parameter :: MASK_28 = int(Z'0FFFFFFF', int32) ! 28-bit DP magnitude
  integer(int32), parameter :: MASK_29 = int(Z'1FFFFFFF', int32) ! 29-bit DP word
  integer(int32), parameter :: SIGN_29 = int(Z'10000000', int32) ! bit 28 = sign

  public :: pack_dp29, unpack_dp29, alu_dad, alu_dsu, alu_dmp

contains

  ! Pack two AGC 15-bit words into a single 29-bit 1's complement integer.
  ! Layout: [Sign(bit28) | High14(bits27-14) | Low14(bits13-0)]
  pure function pack_dp29(hi, lo) result(dp29)
    integer(int32), intent(in) :: hi, lo
    integer(int32) :: dp29
    dp29 = ior(ishft(iand(hi, MASK_15), 14), iand(lo, MASK_14))
  end function pack_dp29

  ! Split a 29-bit 1's complement value back into two AGC 15-bit words.
  ! The low word's sign bit is copied from the high word (AGC convention).
  pure subroutine unpack_dp29(dp29, hi, lo)
    integer(int32), intent(in)  :: dp29
    integer(int32), intent(out) :: hi, lo
    integer(int32) :: sign_bit
    hi = iand(ishft(dp29, -14), MASK_15)
    lo = iand(dp29, MASK_14)
    sign_bit = iand(hi, int(Z'00004000', int32))
    lo = ior(lo, sign_bit)
  end subroutine unpack_dp29

  ! Double-precision ADD with 1's complement End-Around Carry (EAC).
  ! Mirrors the AGC's native DAD / DAS instruction behavior.
  pure subroutine alu_dad(a_hi, a_lo, b_hi, b_lo, res_hi, res_lo, ovfind)
    integer(int32), intent(in)    :: a_hi, a_lo, b_hi, b_lo
    integer(int32), intent(out)   :: res_hi, res_lo
    integer(int32), intent(inout) :: ovfind
    integer(int32) :: a29, b29, sum29, carry
    logical :: sign_a, sign_b, sign_r

    a29 = pack_dp29(a_hi, a_lo)
    b29 = pack_dp29(b_hi, b_lo)
    sum29 = a29 + b29

    ! EAC: fold carry-out of bit 29 back into bit 0
    carry = ishft(sum29, -29)
    sum29 = iand(sum29, MASK_29) + carry
    ! If EAC itself carries (e.g. -0 + -0 = -0)
    if (btest(sum29, 29)) sum29 = iand(sum29, MASK_29) + 1_int32

    ! Overflow: same-sign operands producing opposite-sign result
    sign_a = btest(a29,  28)
    sign_b = btest(b29,  28)
    sign_r = btest(sum29, 28)
    if ((sign_a .eqv. sign_b) .and. (sign_a .neqv. sign_r)) then
      ovfind = merge(-1, 1, sign_a)
    end if

    call unpack_dp29(sum29, res_hi, res_lo)
  end subroutine alu_dad

  ! Double-precision SUBTRACT: A - B  =  A + ~B  (1's complement negate = bitwise NOT)
  pure subroutine alu_dsu(a_hi, a_lo, b_hi, b_lo, res_hi, res_lo, ovfind)
    integer(int32), intent(in)    :: a_hi, a_lo, b_hi, b_lo
    integer(int32), intent(out)   :: res_hi, res_lo
    integer(int32), intent(inout) :: ovfind
    integer(int32) :: inv_b_hi, inv_b_lo
    inv_b_hi = iand(not(b_hi), MASK_15)
    inv_b_lo = iand(not(b_lo), MASK_15)
    call alu_dad(a_hi, a_lo, inv_b_hi, inv_b_lo, res_hi, res_lo, ovfind)
  end subroutine alu_dsu

  ! Double-precision MULTIPLY: fractional 28-bit product.
  ! Both operands are in 1's complement. Result preserves sign correctly.
  ! Binary point is to the left of bit 27 (AGC fractional convention).
  pure subroutine alu_dmp(a_hi, a_lo, b_hi, b_lo, res_hi, res_lo)
    integer(int32), intent(in)  :: a_hi, a_lo, b_hi, b_lo
    integer(int32), intent(out) :: res_hi, res_lo
    integer(int32) :: a29, b29, mag_a, mag_b, res_mag, res29
    integer(int64) :: prod64
    logical :: sign_a, sign_b, sign_res

    a29 = pack_dp29(a_hi, a_lo)
    b29 = pack_dp29(b_hi, b_lo)

    sign_a   = btest(a29,  28)
    sign_b   = btest(b29,  28)
    sign_res = (sign_a .neqv. sign_b)

    ! Magnitude-only multiplication (always positive)
    mag_a = merge(iand(not(a29), MASK_28), iand(a29, MASK_28), sign_a)
    mag_b = merge(iand(not(b29), MASK_28), iand(b29, MASK_28), sign_b)

    ! 56-bit product; shift right 28 to realign fractional binary point
    prod64  = int(mag_a, int64) * int(mag_b, int64)
    res_mag = int(iand(ishft(prod64, -28), int(MASK_28, int64)), int32)

    ! Restore 1's complement sign
    res29 = merge(iand(not(res_mag), MASK_29), res_mag, sign_res)
    call unpack_dp29(res29, res_hi, res_lo)
  end subroutine alu_dmp

end module agc_alu_parity


! ── simple demonstration driver ────────────────────────────────────────────
program alu_demo
  use agc_alu_parity
  use, intrinsic :: iso_fortran_env, only: int32
  implicit none

  integer(int32) :: h1, l1, h2, l2, rh, rl, ovf

  print '(a)', 'AGC 1s-Complement ALU Demo'
  print '(a)', '--------------------------'

  ! +0.5 + +0.5 = +1.0 (overflow expected at DP28 scale)
  h1 = int(Z'2000', int32) ; l1 = 0   ! 0.5 in SP → DP hi
  h2 = h1                   ; l2 = 0
  ovf = 0
  call alu_dad(h1, l1, h2, l2, rh, rl, ovf)
  print '(a,z8,a,z8,a,i2)', 'DAD  0.5+0.5 -> hi=', rh, '  lo=', rl, '  ovf=', ovf

  ! +0.25 - +0.50 = -0.25
  h1 = int(Z'1000', int32) ; l1 = 0   ! 0.25
  h2 = int(Z'2000', int32) ; l2 = 0   ! 0.50
  ovf = 0
  call alu_dsu(h1, l1, h2, l2, rh, rl, ovf)
  print '(a,z8,a,z8,a,i2)', 'DSU  0.25-0.5 -> hi=', rh, '  lo=', rl, '  ovf=', ovf

  ! 0.5 * 0.5 = 0.25
  h1 = int(Z'2000', int32) ; l1 = 0
  h2 = h1                   ; l2 = 0
  call alu_dmp(h1, l1, h2, l2, rh, rl)
  print '(a,z8,a,z8)', 'DMP  0.5*0.5 -> hi=', rh, '  lo=', rl

  print *, 'Done.'
end program alu_demo
