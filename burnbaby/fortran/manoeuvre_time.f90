! manoeuvre_time.f90  — AGC DAP Maneuver Time Kernel
! Original: Angle * ARATE * ANGLTIME → SR 5 → TM
! Rates selected by index 0/1/2/3 (AGC used 0,2,4,6)
!
! Compile: gfortran -std=f2008 manoeuvre_time.f90 -o manoeuvre_time

program manoeuvre_time
  implicit none

  ! ARATE – inverted & scaled rates.  Angle * ARATE * ANGLTIME / 32 = time (sec).
  double precision, parameter :: ARATE(0:3) = [ &
       0.0088888888d0, & ! 0.2 deg/s (index 0)
       0.0222222222d0, & ! 0.5 deg/s (index 1)
       0.0888888888d0, & ! 2.0 deg/s (index 2)
       0.4444444444d0 ] ! 10.0 deg/s (index 3)

  ! ANGLTIME = 100 * 2^{-19} ≈ 0.0001907349
  ! This is the AGC fudge factor that eliminates the hardware divide.
  double precision, parameter :: ANGLTIME = 0.0001907349d0

  double precision :: angle_deg, tm
  integer :: rate_idx

  print '(a)', 'AGC DAP Maneuver-Time Kernel'
  print '(a)', '----------------------------'
  print *

  ! 22.5 deg at 0.2 deg/s -> 112.5 s
  angle_deg = 22.5d0 ; rate_idx = 0
  tm = compute_TM(angle_deg, rate_idx)
  call report(angle_deg, rate_idx, tm)

  ! 45 deg at 2.0 deg/s -> 22.5 s
  angle_deg = 45.0d0 ; rate_idx = 2
  tm = compute_TM(angle_deg, rate_idx)
  call report(angle_deg, rate_idx, tm)

  ! 10 deg at 10 deg/s -> 1.0 s
  angle_deg = 10.0d0 ; rate_idx = 3
  tm = compute_TM(angle_deg, rate_idx)
  call report(angle_deg, rate_idx, tm)

contains

  ! Core kernel: exact analogue of AGC instruction sequence
  !   EXTEND / MP ARATE,INDEX / MP ANGLTIME / SR 5
  pure function compute_TM(angle, idx) result(tm)
    double precision, intent(in) :: angle
    integer, intent(in) :: idx
    double precision :: tm

    if (idx < 0 .or. idx > 3) then
      tm = 0.0d0
      return
    end if

    ! Angle * ARATE * ANGLTIME = product (already scaled B-28)
    ! AGC hardware: SR 5 = divide by 32
    tm = (angle * ARATE(idx) * ANGLTIME) / 32.0d0
  end function compute_TM

  subroutine report(ang, idx, t)
    double precision, intent(in) :: ang, t
    integer, intent(in) :: idx
    character(len=12) :: rate_str

    select case (idx)
    case (0) ; rate_str = '0.2  deg/s'
    case (1) ; rate_str = '0.5  deg/s'
    case (2) ; rate_str = '2.0  deg/s'
    case (3) ; rate_str = '10.0 deg/s'
    case default ; rate_str = '???'
    end select

    ! TM is in AGC internal time units (centiseconds × 2^{-19} scale).
    ! Multiply by 1 / (ANGLTIME * 3276800) ≈ 1 / (0.000625) to get seconds.
    print '(a,f8.2,a,a,a,es14.6e2,a)', &
         'Angle = ', ang, ' deg   Rate = ', trim(rate_str), &
         '   TM = ', t, ' [AGC units]'
  end subroutine report

end program manoeuvre_time
