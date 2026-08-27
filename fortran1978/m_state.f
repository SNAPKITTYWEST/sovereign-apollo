C     M_STATE.F  — Canonical Mission State  (COMMON /MSTATE/)
C     1978 FORTRAN 77 style, fixed-format compatible (columns 1-5 label, 6 cont, 7-72 stmt)
C     Maps to src/mission/state.ts  — see docs/fortran/04_CANONICAL_STATE_SPEC.md
C     Helper: MET H/M/S -> seconds
      INTEGER FUNCTION IMTSEC(IH,IM,IS)
      INTEGER IH,IM,IS
      IMTSEC = IH*3600 + IM*60 + IS
      RETURN
      END
C     Helper: seconds -> H/M/S
      SUBROUTINE ITOMET(ISEC, IH,IM,IS)
      INTEGER ISEC, IH,IM,IS, IREM
      IH = ISEC / 3600
      IREM = ISEC - IH*3600
      IM = IREM / 60
      IS = IREM - IM*60
      RETURN
      END
C     BLOCK DATA for initial state (replaces TS constructor)
      BLOCK DATA MSTDTA
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER IMETSC, IMETH, IVEH, IGUID, IENG, IENGON, ICOMM
      INTEGER IALARM, IPHASE
      REAL*8 POS, VEL, AMASS, AMDRY, CDU, THRUST, ISP, THROTT
      CHARACTER*9 CMET
      COMMON /MSTATE/ IMETSC, IMETH(3), IVEH, IGUID, IENG, THRUST,
     *                ISP, THROTT, IENGON, ICOMM, POS(3), VEL(3),
     *                AMASS, AMDRY, CDU(3), IALARM, IPHASE(8)
      COMMON /MSTATC/ CMET
      DATA IMETSC/0/, IMETH/0,0,0/, IVEH/0/, IGUID/0/, IENG/1/
      DATA THRUST/0.D0/, ISP/311.D0/, THROTT/0.D0/, IENGON/0/
      DATA ICOMM/0/, POS/0.D0,0.D0,0.D0/, VEL/0.D0,0.D0,0.D0/
      DATA AMASS/15000.D0/, AMDRY/4000.D0/, CDU/0.D0,0.D0,0.D0/
      DATA IALARM/0/, IPHASE/8*0/
      DATA CMET/'000:00:00'/
      END
