C     CONTROL.F  — DAP PD + gimbal lock  (src/physics/control.ts)
C     DAPSTP — PD with deadband; jets as bit flags
C     Input: CUR(6)=roll,pitch,yaw, rate(1..3); DES(3)=desired roll,pitch,yaw
C     Output: IJETS bit mask, GIMB(2), Njets count
      SUBROUTINE DAPSTP(CUR, DES, DT, IJETS, NG, GIMB)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 CUR(6), DES(3), DT, GIMB(2), ERRP, ERRR, ERRY
      INTEGER IJETS, NG
      REAL*8 DBAND, RDBAND
      PARAMETER (DBAND=0.3D0, RDBAND=0.3D0)
      ERRP = DES(2) - CUR(2)
      ERRR = DES(1) - CUR(1)
      ERRY = DES(3) - CUR(3)
      IJETS = 0
      NG = 0
C     Pitch jets if |err|>DB or |rate|>RDB
      IF (DABS(ERRP).GT.DBAND .OR. DABS(CUR(5)).GT.RDBAND) THEN
         IF (ERRP.GT.0.D0) IJETS = IJETS + 1
         IF (ERRP.LE.0.D0) IJETS = IJETS + 2
         NG = NG + 1
      ENDIF
      IF (DABS(ERRR).GT.DBAND) THEN
         IF (ERRR.GT.0.D0) IJETS = IJETS + 4
         IF (ERRR.LE.0.D0) IJETS = IJETS + 8
         NG = NG + 1
      ENDIF
      IF (DABS (ERRY).GT.DBAND) THEN
         IF (ERRY.GT.0.D0) IJETS = IJETS + 16
         IF (ERRY.LE.0.D0) IJETS = IJETS + 32
         NG = NG + 1
      ENDIF
      GIMB(1)=ERRP*0.01D0
      GIMB(2)=ERRY*0.01D0
      RETURN
      END
      LOGICAL FUNCTION GLOCKC(CDU2)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 CDU2, GLOCK
      PARAMETER (GLOCK=85.D0)
      GLOCKC = DABS(CDU2) .GT. GLOCK
      RETURN
      END
