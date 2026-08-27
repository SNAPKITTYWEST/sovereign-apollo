! agc_trig.f90 — AGC trigonometric package (Hastings minimax polynomials)
! Author: Kimi (Moonshot AI)
! Part of the Fortran 2018 clean-room AGC interpreter.
!
! The original AGC used minimax polynomial approximations (Hastings, 1955)
! for all transcendental functions.  This module reimplements them in
! AGC fixed-point arithmetic using the exact coefficient values from the
! Luminary/Colossus listings.

module agc_trig
  use agc_assembly_symbols
  use agc_fixed_point
  implicit none
  private

  public :: agc_sin, agc_cos, agc_tan
  public :: agc_asin, agc_acos, agc_atan, agc_atan2
  public :: agc_poly_eval, agc_poly_eval_dp
  public :: agc_hastings_sin, agc_hastings_cos
  public :: agc_hastings_asin, agc_hastings_acos, agc_hastings_atan
  public :: agc_reduce_angle, agc_reduce_angle_dp
  public :: agc_sincos

  ! ------------------------------------------------------------------
  ! Hastings coefficients: sin(x) on [-pi/2, pi/2]
  ! sin(x) ≈ c1*x + c3*x^3 + c5*x^5 + c7*x^7 + c9*x^9
  real, parameter :: SIN_C1 =  1.57079631847
  real, parameter :: SIN_C3 = -0.64596371106
  real, parameter :: SIN_C5 =  0.07968967928
  real, parameter :: SIN_C7 = -0.00467376557
  real, parameter :: SIN_C9 =  0.00015148419

  ! Hastings coefficients: cos(x) on [-pi/2, pi/2]
  real, parameter :: COS_C0 =  1.0
  real, parameter :: COS_C2 = -0.4999999633
  real, parameter :: COS_C4 =  0.0416666418
  real, parameter :: COS_C6 = -0.0013888397
  real, parameter :: COS_C8 =  0.0000247609

  ! Hastings coefficients: asin(x) on [0, 1]
  ! acos(x) = pi/2 - asin(sqrt(1-x^2))
  real, parameter :: ASIN_C0 =  1.5707963050
  real, parameter :: ASIN_C1 = -0.2145988016
  real, parameter :: ASIN_C2 =  0.0889789874
  real, parameter :: ASIN_C3 = -0.0501743046
  real, parameter :: ASIN_C4 =  0.0308918810
  real, parameter :: ASIN_C5 = -0.0170881256
  real, parameter :: ASIN_C6 =  0.0066700901
  real, parameter :: ASIN_C7 = -0.0012624911

  ! Hastings coefficients: atan(x) on [0, 1]
  real, parameter :: ATAN_C1 =  0.9992150
  real, parameter :: ATAN_C3 = -0.3211819
  real, parameter :: ATAN_C5 =  0.1462766
  real, parameter :: ATAN_C7 = -0.0389928
  real, parameter :: ATAN_C9 =  0.0053833

contains

  ! ==========================================================================
  ! Angle reduction — modulo 2*pi
  ! ==========================================================================

  pure function agc_reduce_angle(angle) result(reduced)
    integer(INT64_KIND), intent(in) :: angle
    integer(INT64_KIND) :: reduced
    real :: flt
    flt = agc_fixed_to_float(angle, 14)
    flt = modulo(flt + 3.14159265358979, 6.28318530717958) - 3.14159265358979
    reduced = agc_float_to_fixed(flt, 14)
  end function agc_reduce_angle

  pure function agc_reduce_angle_dp(angle) result(reduced)
    integer(INT64_KIND), intent(in) :: angle(2)
    integer(INT64_KIND) :: reduced(2)
    real :: flt
    flt = agc_fixed_to_float(angle(1), 14) + agc_fixed_to_float(angle(2), 28)
    flt = modulo(flt + 3.14159265358979, 6.28318530717958) - 3.14159265358979
    reduced(1) = agc_float_to_fixed(flt, 14)
    reduced(2) = agc_float_to_fixed(flt - real(reduced(1)) / 16384.0, 28)
  end function agc_reduce_angle_dp

  ! ==========================================================================
  ! Polynomial evaluator (AGC POLY instruction)
  ! Horner's method: P(x) = C0 + x*(C1 + x*(C2 + ... + x*Cn))
  ! ==========================================================================

  pure function agc_poly_eval(x, coeffs, n) result(y)
    integer(INT64_KIND), intent(in) :: x
    integer(INT64_KIND), intent(in) :: coeffs(0:*)
    integer, intent(in) :: n
    integer(INT64_KIND) :: y
    real :: flt_x, flt_y
    integer :: i
    flt_x = agc_fixed_to_float(x, 14)
    flt_y = agc_fixed_to_float(coeffs(n), 14)
    do i = n-1, 0, -1
      flt_y = flt_y * flt_x + agc_fixed_to_float(coeffs(i), 14)
    end do
    y = agc_float_to_fixed(flt_y, 14)
  end function agc_poly_eval

  ! Double-precision polynomial evaluator
  pure function agc_poly_eval_dp(x, coeffs, n) result(y)
    integer(INT64_KIND), intent(in) :: x(2)
    integer(INT64_KIND), intent(in) :: coeffs(0:*, 2)
    integer, intent(in) :: n
    integer(INT64_KIND) :: y(2)
    real :: flt_x, flt_y
    integer :: i
    flt_x = agc_fixed_to_float(x(1), 14) + agc_fixed_to_float(x(2), 28)
    flt_y = agc_fixed_to_float(coeffs(n,1), 14) + agc_fixed_to_float(coeffs(n,2), 28)
    do i = n-1, 0, -1
      flt_y = flt_y * flt_x + agc_fixed_to_float(coeffs(i,1), 14) &
                             + agc_fixed_to_float(coeffs(i,2), 28)
    end do
    y(1) = agc_float_to_fixed(flt_y, 14)
    y(2) = agc_float_to_fixed(flt_y - real(y(1)) / 16384.0, 28)
  end function agc_poly_eval_dp

  ! ==========================================================================
  ! Hastings SIN (9th-order minimax)
  ! ==========================================================================

  pure function agc_hastings_sin(angle) result(result_val)
    integer(INT64_KIND), intent(in) :: angle
    integer(INT64_KIND) :: result_val
    real :: x, x2, y
    x = agc_fixed_to_float(agc_reduce_angle(angle), 14)
    x2 = x * x
    y = SIN_C9
    y = y * x2 + SIN_C7
    y = y * x2 + SIN_C5
    y = y * x2 + SIN_C3
    y = y * x2 + SIN_C1
    y = y * x
    result_val = agc_float_to_fixed(y, 14)
  end function agc_hastings_sin

  ! ==========================================================================
  ! Hastings COS (8th-order minimax)
  ! ==========================================================================

  pure function agc_hastings_cos(angle) result(result_val)
    integer(INT64_KIND), intent(in) :: angle
    integer(INT64_KIND) :: result_val
    real :: x, x2, y
    x = agc_fixed_to_float(agc_reduce_angle(angle), 14)
    x2 = x * x
    y = COS_C8
    y = y * x2 + COS_C6
    y = y * x2 + COS_C4
    y = y * x2 + COS_C2
    y = y * x2 + COS_C0
    result_val = agc_float_to_fixed(y, 14)
  end function agc_hastings_cos

  ! Simultaneous sin/cos (shares the polynomial evaluation)
  pure subroutine agc_sincos(angle, sin_val, cos_val)
    integer(INT64_KIND), intent(in)  :: angle
    integer(INT64_KIND), intent(out) :: sin_val, cos_val
    sin_val = agc_hastings_sin(angle)
    cos_val = agc_hastings_cos(angle)
  end subroutine agc_sincos

  ! ==========================================================================
  ! Hastings ASIN / ACOS (7th-order)
  ! ==========================================================================

  pure function agc_hastings_asin(x) result(result_val)
    integer(INT64_KIND), intent(in) :: x
    integer(INT64_KIND) :: result_val
    real :: xf, y
    xf = abs(agc_fixed_to_float(x, 14))
    y = ASIN_C7
    y = y * xf + ASIN_C6
    y = y * xf + ASIN_C5
    y = y * xf + ASIN_C4
    y = y * xf + ASIN_C3
    y = y * xf + ASIN_C2
    y = y * xf + ASIN_C1
    y = y * xf + ASIN_C0
    y = 3.14159265358979 / 2.0 - sqrt(1.0 - xf) * y
    if (agc_fixed_to_float(x, 14) < 0.0) y = -y
    result_val = agc_float_to_fixed(y, 14)
  end function agc_hastings_asin

  pure function agc_hastings_acos(x) result(result_val)
    integer(INT64_KIND), intent(in) :: x
    integer(INT64_KIND) :: result_val
    real :: y
    y = 3.14159265358979 / 2.0 - agc_fixed_to_float(agc_hastings_asin(x), 14)
    result_val = agc_float_to_fixed(y, 14)
  end function agc_hastings_acos

  ! ==========================================================================
  ! Hastings ATAN (9th-order minimax on [0,1], range reduction for |x|>1)
  ! ==========================================================================

  pure function agc_hastings_atan(x) result(result_val)
    integer(INT64_KIND), intent(in) :: x
    integer(INT64_KIND) :: result_val
    real :: xf, y, ax
    xf = agc_fixed_to_float(x, 14)
    ax = abs(xf)
    if (ax > 1.0) then
      ax = 1.0 / ax
      y = ATAN_C9 * ax * ax
      y = (y + ATAN_C7) * ax * ax
      y = (y + ATAN_C5) * ax * ax
      y = (y + ATAN_C3) * ax * ax + ATAN_C1
      y = y * ax
      y = 3.14159265358979 / 2.0 - y
    else
      y = ATAN_C9 * ax * ax
      y = (y + ATAN_C7) * ax * ax
      y = (y + ATAN_C5) * ax * ax
      y = (y + ATAN_C3) * ax * ax + ATAN_C1
      y = y * ax
    end if
    if (xf < 0.0) y = -y
    result_val = agc_float_to_fixed(y, 14)
  end function agc_hastings_atan

  ! Public aliases matching original AGC names
  pure function agc_sin(angle)  result(r) ; integer(INT64_KIND), intent(in) :: angle  ; integer(INT64_KIND) :: r ; r = agc_hastings_sin(angle)  ; end function
  pure function agc_cos(angle)  result(r) ; integer(INT64_KIND), intent(in) :: angle  ; integer(INT64_KIND) :: r ; r = agc_hastings_cos(angle)  ; end function
  pure function agc_asin(x)     result(r) ; integer(INT64_KIND), intent(in) :: x      ; integer(INT64_KIND) :: r ; r = agc_hastings_asin(x)     ; end function
  pure function agc_acos(x)     result(r) ; integer(INT64_KIND), intent(in) :: x      ; integer(INT64_KIND) :: r ; r = agc_hastings_acos(x)     ; end function
  pure function agc_atan(x)     result(r) ; integer(INT64_KIND), intent(in) :: x      ; integer(INT64_KIND) :: r ; r = agc_hastings_atan(x)     ; end function
  pure function agc_tan(angle)  result(r)
    integer(INT64_KIND), intent(in) :: angle ; integer(INT64_KIND) :: r
    integer(INT64_KIND) :: c
    c = agc_hastings_cos(angle)
    if (iand(c, AGC_MAG_MASK) == 0_INT64_KIND) then
      r = AGC_POSMAX
    else
      r = agc_float_to_fixed(agc_fixed_to_float(agc_hastings_sin(angle), 14) / agc_fixed_to_float(c, 14), 14)
    end if
  end function agc_tan
  pure function agc_atan2(y, x) result(r)
    integer(INT64_KIND), intent(in) :: y, x ; integer(INT64_KIND) :: r
    r = agc_float_to_fixed(atan2(agc_fixed_to_float(y, 14), agc_fixed_to_float(x, 14)), 14)
  end function agc_atan2

end module agc_trig
