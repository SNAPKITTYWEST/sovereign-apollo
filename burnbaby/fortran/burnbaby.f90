! burnbaby.f90  — Master Ignition Routine (Fortran abstraction of AGC Luminary)
! Original: Adler & Eyles, Apollo LM AGC, Comanche/Luminary.
! "Honi soit qui mal y pense"
!
! Architecture: Janet-table driven state machine.
!   WHICH selects one of six program variants (P12/P40/P41/P42/P63/ABORT).
!   The same countdown chain (TIG-35 → TIG-30 → TIG-5 → TIG-0 → IGNITION)
!   executes for all variants; per-program branches are resolved entirely via
!   table lookups into Janet(WHICH, offset).
!
! Compile: gfortran -std=f2008 burnbaby.f90 -o burnbaby_demo

program burnbaby
  implicit none

  ! ── Symbolic branch codes (replace AGC absolute TCF addresses) ────────────
  integer, parameter :: ULLGNOT  = 101, WANTAPS  = 102
  integer, parameter :: COMFAIL3 = 103, COMFAIL4 = 104
  integer, parameter :: GOCUTOFF = 105, GOPOST   = 106
  integer, parameter :: V99RECYC = 107, TASKOVER = 108

  integer, parameter :: P12SPOT  = 201, P40SPOT  = 202
  integer, parameter :: P41SPOT  = 203, P42SPOT  = 204
  integer, parameter :: P63SPOT  = 205

  integer, parameter :: DISPCHNG = 301, WAITABIT = 302
  integer, parameter :: TIGTASK  = 303, CMPATH   = 304   ! CMPATH avoids keyword clash

  integer, parameter :: P12IGN   = 401, P40IGN   = 402
  integer, parameter :: P42IGN   = 403, P63IGN   = 404
  integer, parameter :: ABRTIGN  = 405

  integer, parameter :: REP40ALM = 501, P42STAGE = 502
  integer, parameter :: NOOP     = 0

  integer, parameter :: NPROG  = 6   ! P12 P40 P41 P42 P63 ABRT
  integer, parameter :: NENTRY = 15  ! Janet column count

  ! ── Global state (erasable memory abstraction) ────────────────────────────
  integer :: Janet(0:NPROG-1, 0:NENTRY-1)
  integer :: WHICH = 0              ! Program selector (0=P12 … 5=ABRT)
  integer :: DVTOTAL(2)
  integer :: DISPDEX, PHASE3, PHASE4
  integer :: FLGWRD10, DAPBOOLS
  integer :: TIG(2), TGO(2), TEVENT(2), SAVET30(2)
  integer :: AVEGEXIT(2), THRUST
  logical :: IGNFLAG, ASTNFLAG, IDLEFLAG, ENGONFLG, MUNFLAG

  ! ── Entry ─────────────────────────────────────────────────────────────────
  DVTOTAL  = 0
  IGNFLAG  = .false.
  ASTNFLAG = .false.
  IDLEFLAG = .true.
  ENGONFLG = .false.
  MUNFLAG  = .false.

  call init_Janet_tables()
  call demo_run()

contains

  ! ── Fill Janet table from program-specific constant tables ─────────────────
  subroutine init_Janet_tables()
    Janet = 0

    ! P12TABLE (Command Module DPS backup)
    Janet(0,0) = 0674            ! VN display code
    Janet(0,1) = ULLGNOT
    Janet(0,2) = COMFAIL3
    Janet(0,3) = GOCUTOFF
    Janet(0,4) = TASKOVER
    Janet(0,5) = P12SPOT
    Janet(0,6) = 0               ! no ullage
    Janet(0,8) = DISPCHNG        ! offset 11
    Janet(0,9) = WAITABIT        ! offset 12
    Janet(0,10)= P12IGN          ! offset 13

    ! P40TABLE (DPS powered descent)
    Janet(1,0) = 0640
    Janet(1,1) = ULLGNOT
    Janet(1,2) = COMFAIL4
    Janet(1,3) = GOPOST
    Janet(1,4) = TASKOVER
    Janet(1,5) = P40SPOT
    Janet(1,6) = 2240            ! ullage Δt (csec)
    Janet(1,8) = 301
    Janet(1,9) = WAITABIT
    Janet(1,10)= P40IGN
    Janet(1,11)= REP40ALM        ! offset 14

    ! P41TABLE (CSM SPS without abort)
    Janet(2,5) = P41SPOT
    Janet(2,6) = -1              ! special: no ullage, blank DSKY
    Janet(2,8) = CMPATH
    Janet(2,9) = TIGTASK

    ! P42TABLE (CSM SPS with abort)
    Janet(3,0) = 0640
    Janet(3,1) = WANTAPS
    Janet(3,2) = COMFAIL4
    Janet(3,3) = GOPOST
    Janet(3,4) = TASKOVER
    Janet(3,5) = P42SPOT
    Janet(3,6) = 2640
    Janet(3,8) = 301
    Janet(3,9) = WAITABIT
    Janet(3,10)= P42IGN
    Janet(3,11)= P42STAGE

    ! P63TABLE (Powered Descent Initiation)
    Janet(4,0) = 0662
    Janet(4,1) = ULLGNOT
    Janet(4,2) = COMFAIL3
    Janet(4,3) = V99RECYC
    Janet(4,4) = TASKOVER
    Janet(4,5) = P63SPOT
    Janet(4,6) = 2240
    Janet(4,8) = DISPCHNG
    Janet(4,9) = WAITABIT
    Janet(4,10)= P63IGN

    ! ABRTABLE (Abort)
    Janet(5,0) = 0663
    Janet(5,1) = ULLGNOT
    Janet(5,2) = COMFAIL3
    Janet(5,3) = GOCUTOFF
    Janet(5,4) = TASKOVER
    Janet(5,5) = NOOP
    Janet(5,6) = NOOP
    Janet(5,8) = DISPCHNG
    Janet(5,9) = WAITABIT
    Janet(5,10)= ABRTIGN
  end subroutine init_Janet_tables

  ! ─────────────────────────────────────────────────────────────────────────
  ! BURNBABY_entry — Phase-protected entry; dispatches to program SPOT
  ! AGC: TC PHASCHNG / OCT 04024 / EXTIRPATE DVTOTAL / INDEX WHICH / TCF 5
  ! ─────────────────────────────────────────────────────────────────────────
  subroutine BURNBABY_entry()
    call phase_change(4, 4024)    ! restart group 4
    DVTOTAL = 0                   ! extirpate junk left in DVTOTAL
    call P40AUTO()
    call inhibit()
    call ENGINOF3()
    call release()

    select case (Janet(WHICH, 5))
    case (P40SPOT, P12SPOT, P42SPOT)
      call P40SPOT_logic()
    case (P41SPOT, P63SPOT)
      call P41SPOT_logic()
    case default
      call P40SPOT_logic()
    end select
  end subroutine BURNBABY_entry

  ! ── TIG-35 setup paths ───────────────────────────────────────────────────

  subroutine P40SPOT_logic()
    ! CS CNTDNDEX / BANKCALL STCLOK2  (start countdown clock display)
    call STCLOK2()
    call CALLT_35()
  end subroutine P40SPOT_logic

  subroutine P41SPOT_logic()
    ! TC INTPRET / DLOAD DSU TIG,D29.9SEC / STCALL INITCDUW
    ! BOFF MUNFLAG GOMIDAV / CALL CSMPREC / VLOAD MXV …
    ! Compress state vectors through MIDTOAV1, then fall to CALLT_35.
    if (.not. MUNFLAG) call MIDTOAV1()
    call CALLT_35()
  end subroutine P41SPOT_logic

  subroutine CALLT_35()
    ! Schedule LONGCALL for TIG−35 s
    call phase_change(4, 20254)
    if (WHICH == 4) DISPDEX = -17   ! P63: init countdown CNTDNDEX
  end subroutine CALLT_35

  ! ── TIG-35 timed task ────────────────────────────────────────────────────

  subroutine TIG_35()
    ! Blank DSKY for 5 s; optionally start ullage motor task
    call phase_change(4, 40154)
    DISPDEX = -2                    ! BLANKDEX
    if (Janet(WHICH, 6) > 0) then
      call TWIDDLE(Janet(WHICH, 6), TIG_30_ullage)   ! ullage start
    end if
    call TWIDDLE(500, TIG_30)       ! 5 s to TIG-30
  end subroutine TIG_35

  ! ── TIG-30 timed task ────────────────────────────────────────────────────

  subroutine TIG_30()
    ! Restore countdown display; handle program-specific ullage/APS arming
    call TWIDDLE(2490, TIG_5)       ! 24.9 s to TIG-5
    DISPDEX = -17                   ! restart CLOKTASK

    select case (Janet(WHICH, 1))
    case (WANTAPS)
      FLGWRD10 = ior(FLGWRD10, 1)  ! set APSFLAG
    case default
      ! ULLGNOT: no action required here
    end select

    call ULLGNOT_logic()
  end subroutine TIG_30

  subroutine TIG_30_ullage()
    call ONULLAGE()
    call phase_change(1, 1)
  end subroutine TIG_30_ullage

  subroutine ULLGNOT_logic()
    ! Load AVEGEXIT from Janet entry 7; set PHASE4 for TIG-5 restart.
    ! If SERVICER not running, schedule PREREAD.
    PHASE4 = 1
  end subroutine ULLGNOT_logic

  ! ── TIG-5 timed task ─────────────────────────────────────────────────────

  subroutine TIG_5()
    ! Clear PHASE3; schedule TIG-0; display V99 "Please Enable Engine"
    PHASE3 = 0
    call TWIDDLE(500, TIG_0)        ! 5 s to TIG-0
    call DOWNFLAG(IGNFLAG)
    call DOWNFLAG(ASTNFLAG)

    ! Janet offset 8 branch: 301 == DISPCHNG; CMPATH is separate code
    if (Janet(WHICH, 8) == CMPATH) then
      call CMPATH_logic()
    else
      call DISPCHNG_logic()   ! covers 301 (P40SJUNK path) and DISPCHNG
    end if
  end subroutine TIG_5

  subroutine DISPCHNG_logic()
    DISPDEX = -13           ! VB99DEX — "please enable engine"
    call CMPATH_logic()
  end subroutine DISPCHNG_logic

  subroutine CMPATH_logic()
    call phase_change(4, 40074)    ! restart protect TIG-0
  end subroutine CMPATH_logic

  ! ── TIG-0 timed task ─────────────────────────────────────────────────────

  subroutine TIG_0()
    ! IGNYET? check: astronaut must have pressed V99 PROCEED
    call UPFLAG(IGNFLAG)

    if (WHICH == 4) call P63ZOOM()  ! PDI special: WAITLIST ZOOMTIME P63ZOOM

    if (.not. ASTNFLAG) then
      ! Astronaut has not yet enabled engine
      select case (Janet(WHICH, 9))
      case (WAITABIT)
        call WAITABIT_logic()
      case (TIGTASK)
        call TIGTASK_logic()
      end select
      return
    end if

    call IGNITION()
  end subroutine TIG_0

  ! ── Ignition dispatch ────────────────────────────────────────────────────

  subroutine IGNITION()
    ! Set engine-on flag; write DSALMOUT bit 13; capture TEVENT.
    call UPFLAG(ENGONFLG)
    TEVENT(1) = 0  ! TIME2 would be read here in real AGC

    ! Dispatch by program via Janet offset 13
    select case (Janet(WHICH, 10))
    case (P63IGN)  ; call P63IGN_logic()
    case (P40IGN)  ; call P40IGN_logic()
    case (P12IGN)  ; call P12IGN_logic()
    case (ABRTIGN) ; call ABRTIGN_logic()
    case (P42IGN)  ; call P42IGN_logic()
    case default
      call WAITABIT_logic()
    end select
  end subroutine IGNITION

  subroutine P63IGN_logic()
    ! Kill CLOKTASK; set LETABBIT & SWANDBIT; force DAP out of min-impulse.
    ! Falls through to P42IGN_logic.
    call P42IGN_logic()
  end subroutine P63IGN_logic

  subroutine P40IGN_logic()
    ! NOTHRBIT check: WAITLIST ZOOMTIME P40ZOOM
    THRUST = ior(0, ishft(1, 12))  ! BIT13
    call P42IGN_logic()
  end subroutine P40IGN_logic

  subroutine P12IGN_logic()
    ! Init AOSQ / AOSR DAP bias registers.
    call ABRTIGN_logic()
  end subroutine P12IGN_logic

  subroutine ABRTIGN_logic()
    ! Kill CLOKTASK; AVGEXIT ← ATMAG; enable R10.
    call P42IGN_logic()
  end subroutine ABRTIGN_logic

  subroutine P42IGN_logic()
    ! Clear DRIFTBIT (powered-flight DAP curves).
    call DVMONCON()
  end subroutine P42IGN_logic

  subroutine DVMONCON()
    ! DV monitor connect: clear flags, phase-protect, delay 0.5 s.
    call DOWNFLAG(IGNFLAG)
    call DOWNFLAG(ASTNFLAG)
    call DOWNFLAG(IDLEFLAG)
    call phase_change(4, 40054)
    call FIXDELAY(50)              ! 0.5 s
    call ULLAGOFF()
    call WAITABIT_logic()
  end subroutine DVMONCON

  subroutine WAITABIT_logic()
    ! Kill Group 4 — TASKOVER
  end subroutine WAITABIT_logic

  subroutine TIGTASK_logic()
    ! NOVAC TIGNOW; kill Group 6.
  end subroutine TIGTASK_logic

  ! ── Supporting stubs (real AGC would call BANKCALL / WAITLIST) ───────────

  subroutine P40AUTO()
    ! Verify G+N mode and AUTO switch; if not, flash V50N25 checklist 203.
  end subroutine P40AUTO

  subroutine MIDTOAV1()
    ! Compute mid-course to apogee vector for P41.
  end subroutine MIDTOAV1

  subroutine P63ZOOM()
    ! AVEGEXIT ← LUNLANAD; FLATOUT; then P40ZOOM path.
    THRUST = ior(0, ishft(1, 12))
  end subroutine P63ZOOM

  subroutine ONULLAGE()
    DAPBOOLS = ior(DAPBOOLS, 1)
  end subroutine ONULLAGE

  subroutine NOULLAGE()
    DAPBOOLS = iand(DAPBOOLS, not(1))
  end subroutine NOULLAGE

  subroutine ULLAGOFF()
    call NOULLAGE()
  end subroutine ULLAGOFF

  subroutine STCLOK2()   ! start countdown display task
  end subroutine STCLOK2

  subroutine ENGINOF3()  ! engine-off safety
  end subroutine ENGINOF3

  subroutine FIXDELAY(cs)
    integer, intent(in) :: cs
  end subroutine FIXDELAY

  subroutine inhibit()
  end subroutine inhibit

  subroutine release()
  end subroutine release

  subroutine phase_change(grp, octal)
    integer, intent(in) :: grp, octal
    ! Restart-protection: record phase in PHASE table.
  end subroutine phase_change

  subroutine TWIDDLE(dt_csec, task)
    ! Schedule a waitlist task dt_csec centiseconds in the future.
    ! In the real AGC this would call WAITLIST.
    integer, intent(in) :: dt_csec
    external :: task
  end subroutine TWIDDLE

  subroutine DOWNFLAG(flag) ; logical, intent(out) :: flag ; flag = .false. ; end subroutine
  subroutine UPFLAG(flag)   ; logical, intent(out) :: flag ; flag = .true.  ; end subroutine

  ! ── Demo ─────────────────────────────────────────────────────────────────

  subroutine demo_run()
    integer :: prog
    character(len=4), parameter :: PROG_NAME(0:5) = &
        ['P12 ', 'P40 ', 'P41 ', 'P42 ', 'P63 ', 'ABRT']

    print '(a)', 'BURNBABY — Janet-table driven state machine'
    print '(a)', '-------------------------------------------'

    do prog = 0, NPROG - 1
      WHICH = prog
      ASTNFLAG = (prog /= 3)   ! P42 simulates no astronaut proceed
      print '(a,a,a,l1)', '  WHICH=', PROG_NAME(prog), '  ASTNFLAG=', ASTNFLAG
      call BURNBABY_entry()
    end do

    print *
    print '(a)', 'Janet table (program x offset 0..10):'
    do prog = 0, NPROG - 1
      print '(a,a,11i6)', '  ', PROG_NAME(prog), Janet(prog, 0:10)
    end do
  end subroutine demo_run

end program burnbaby
