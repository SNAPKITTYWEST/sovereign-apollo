C     VERIFICATION.F  — assertInvariant  (src/sovereign/verification.ts)
C     IERR 0 ok, 1 throttle, 2 mass
      SUBROUTINE ASSINV(IERR)
      INTEGER IERR, IMETSC, IMETH, IVEH, IGUID, IENG, IENGON, ICOMM
      INTEGER IALARM, IPHASE
      REAL*8 POS, VEL, AMASS, AMDRY, CDU, THRUST, ISP, THROTT
      CHARACTER*9 CMET
      COMMON /MSTATE/ IMETSC, IMETH(3), IVEH, IGUID, IENG, THRUST,
     *                ISP, THROTT, IENGON, ICOMM, POS(3), VEL(3),
     *                AMASS, AMDRY, CDU(3), IALARM, IPHASE(8)
      COMMON /MSTATC/ CMET
      IERR=0
      IF (IGUID.EQ.63 .OR. IGUID.EQ.64) THEN
         IF (THROTT .NE. 0.D0) THEN
            IF (THROTT .LT. 0.09D0 .OR. THROTT .GT. 0.95D0) THEN
               IERR=1
               RETURN
            ENDIF
         ENDIF
      ENDIF
      IF (AMASS .LT. AMDRY) THEN
         IERR=2
         RETURN
      ENDIF
      RETURN
      END
