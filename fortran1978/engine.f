C     ENGINE.F  — Physics Engine + Servicer  (src/physics/engine.ts)
      BLOCK DATA PHYDTA
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 DTMS, GMOON
      INTEGER ISRVAC
      PARAMETER (GMOON=1.62D0)
      COMMON /PHYSCF/ DTMS, ISRVAC
      DATA DTMS/1.D0/, ISRVAC/0/
      END
C     ENGSTP — Integrate one minor cycle dt (seconds); accum to 2000ms Servicer
      SUBROUTINE ENGSTP(DT, IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 DT, THRUST, ISP, THROTT, POS, VEL, AMASS, AMDRY, CDU
      REAL*8 GMOON, MASSFL, DTMS
      INTEGER IMETSC, IMETH, IVEH, IGUID, IENG, IENGON, ICOMM
      INTEGER IALARM, IPHASE, ISRVAC, IERR, I
      CHARACTER*8 CMET
      COMMON /MSTATE/ IMETSC, IMETH(3), IVEH, IGUID, IENG, THRUST,
     *                ISP, THROTT, IENGON, ICOMM, POS(3), VEL(3),
     *                AMASS, AMDRY, CDU(3), IALARM, IPHASE(8)
      COMMON /MSTATC/ CMET
      COMMON /PHYSCF/ DTMS, ISRVAC
      PARAMETER (GMOON=1.62D0)
      IERR=0
C     Thrust → velocity[3] (local +Z per engine.ts:19 stub)
      IF (THRUST .GT. 0.D0) THEN
         VEL(3) = VEL(3) + (THRUST/AMASS)*DT
         AMASS = AMASS - MASSFL(THRUST,ISP)*DT
         IF (AMASS .LT. AMDRY) AMASS = AMDRY
      ENDIF
C     Gravity stub: - G*0.1 per engine.ts:23 INFERRED
      VEL(3) = VEL(3) - GMOON*0.1D0*DT
C     Position
      DO 10 I=1,3
        POS(I)=POS(I)+VEL(I)*DT
 10   CONTINUE
      ISRVAC = ISRVAC + INT(DT*1000.D0)
      IF (ISRVAC .GE. 2000) THEN
         CALL SVCTCK(IERR)
         ISRVAC=0
      ENDIF
      RETURN
      END
      SUBROUTINE SVCTCK(IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER IERR
C     Servicer 2-s tick placeholder — guidance invariants + throttle already in UPDGUID
C     Telemetry scheduling already in BFRAME
      IERR=0
      RETURN
      END
C     MASSFL now in propulsion.f (avoid duplicate)
