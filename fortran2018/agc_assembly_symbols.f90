! agc_assembly_symbols.f90 — AGC word constants and numeric kinds
! Author: Kimi (Moonshot AI)
! Part of the Fortran 2018 clean-room AGC interpreter implementation.
! Companion to agc_fixed_point.f90 and agc_trig.f90.
!
! The AGC used 15-bit 1's complement words.  Bit 15 (0-indexed: bit 14)
! is the sign bit.  +0 = 0x0000, -0 = 0x7FFF.

module agc_assembly_symbols
  use, intrinsic :: iso_fortran_env, only : int32, int64, real64
  implicit none
  public

  integer, parameter :: INT64_KIND = int64

  ! 15-bit word masks
  integer(INT64_KIND), parameter :: AGC_WORD_BITS = 15_INT64_KIND
  integer(INT64_KIND), parameter :: AGC_WORD_MASK = int(z'7FFF', INT64_KIND)
  integer(INT64_KIND), parameter :: AGC_SIGN_BIT  = int(z'4000', INT64_KIND)
  integer(INT64_KIND), parameter :: AGC_MAG_MASK  = int(z'3FFF', INT64_KIND)

  ! 1's complement zero representations
  integer(INT64_KIND), parameter :: AGC_PLUS_ZERO  = 0_INT64_KIND
  integer(INT64_KIND), parameter :: AGC_MINUS_ZERO = AGC_WORD_MASK  ! 0x7FFF

  ! Double-precision (28-bit magnitude + sign)
  integer(INT64_KIND), parameter :: AGC_DP_MASK    = int(z'0FFFFFFF', INT64_KIND)
  integer(INT64_KIND), parameter :: AGC_DP_SIGN    = int(z'10000000', INT64_KIND)

  ! Common AGC constants (fixed-point, B-14 scaling)
  integer(INT64_KIND), parameter :: AGC_POSMAX = int(z'3FFF', INT64_KIND)  ! +1 - LSB
  integer(INT64_KIND), parameter :: AGC_NEGMAX = int(z'4001', INT64_KIND)  ! -(1 - 2*LSB)
  integer(INT64_KIND), parameter :: AGC_HALF   = int(z'2000', INT64_KIND)  ! 0.5
  integer(INT64_KIND), parameter :: AGC_QUARTER= int(z'1000', INT64_KIND)  ! 0.25
  integer(INT64_KIND), parameter :: AGC_ONE    = int(z'4000', INT64_KIND)  ! 1.0 (overflow)

  ! Pi constants (octal, B-14 scaling)
  integer(INT64_KIND), parameter :: AGC_PI_HALF = int(o'31103', INT64_KIND)
  integer(INT64_KIND), parameter :: AGC_PI      = int(o'62207', INT64_KIND)

end module agc_assembly_symbols
