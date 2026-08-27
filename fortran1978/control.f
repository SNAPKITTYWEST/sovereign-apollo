C     CONTROL.F  — DAP PD + gimbal lock + TJETLAW Zones 1-5
C     Implements Apollo TJETLAW phase-plane logic (A. Kalman, 1968)
C     Zones: 1 drift, 2 coast, 3 rate-damp, 4 position-correct, 5 hard-fire
C     Input: CUR(6)=roll,pitch,yaw, rateX/Y/Z; DES(3)=desired
C     Output: IJETS bit mask (1=P+,2=P-,4=R+,8=R-,16=Y+,32=Y-), NG, GIMB(2)
      SUBROUTINE DAPSTP(CUR, DES, DT, IJETS, NG, GIMB)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 CUR(6), DES(3), DT, GIMB(2)
      INTEGER IJETS, NG
      CALL TJETLAW(CUR, DES, IJETS, NG, GIMB)
      RETURN
      END
C     TJETLAW — Zone 1-5 jet selection per axis
      SUBROUTINE TJETLAW(CUR, DES, IJETS, NG, GIMB)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 CUR(6), DES(3), GIMB(2), ERR(3), RAT(3)
      INTEGER IJETS, NG, I, BITP, BITN
      REAL*8 DBAND, RDBAND, ERRABS, RATABS, PRATE
      PARAMETER (DBAND=0.3D0, RDBAND=0.3D0)
      ERR(1) = DES(1) - CUR(1)
      ERR(2) = DES(2) - CUR(2)
      ERR(3) = DES(3) - CUR(3)
      RAT(1) = CUR(4)
      RAT(2) = CUR(5)
      RAT(3) = CUR(6)
      IJETS = 0
      NG = 0
      DO 10 I=1,3
         ERRABS = DABS(ERR(I))
         RATABS = DABS(RAT(I))
         PRATE = ERR(I)*RAT(I)
C        Bit mapping: roll 4/8, pitch 1/2, yaw 16/32
         IF (I.EQ.1) THEN
            BITP = 4
            BITN = 8
         ELSE IF (I.EQ.2) THEN
            BITP = 1
            BITN = 2
         ELSE
            BITP = 16
            BITN = 32
         ENDIF
C        Zone 1: inside deadband, low rate → drift, no jets
         IF (ERRABS .LT. DBAND .AND. RATABS .LT. RDBAND) THEN
            GOTO 10
         ENDIF
C        Zone 2: inside deadband, rate toward center → coast
         IF (ERRABS .LT. DBAND .AND. PRATE .LT. 0.D0) THEN
            GOTO 10
         ENDIF
C        Zone 3: small error, rate away → rate-damp (fire opposite rate)
         IF (ERRABS .LT. DBAND*2.D0 .AND. PRATE .GT. 0.D0) THEN
            IF (RAT(I) .GT. 0.D0) IJETS = IJETS + BITN
            IF (RAT(I) .LT. 0.D0) IJETS = IJETS + BITP
            NG = NG + 1
            GOTO 10
         ENDIF
C        Zone 4: moderate error → position correct
         IF (ERRABS .LT. DBAND*5.D0) THEN
            IF (ERR(I) .GT. 0.D0) IJETS = IJETS + BITP
            IF (ERR(I) .LT. 0.D0) IJETS = IJETS + BITN
            NG = NG + 1
            GOTO 10
         ENDIF
C        Zone 5: large error → hard fire (always)
         IF (ERR(I) .GT. 0.D0) IJETS = IJETS + BITP
         IF (ERR(I) .LT. 0.D0) IJETS = IJETS + BITN
         NG = NG + 1
 10   CONTINUE
C     Gimbal trim from pitch/yaw error (powered flight)
      GIMB(1)=ERR(2)*0.01D0
      GIMB(2)=ERR(3)*0.01D0
      RETURN
      END
      LOGICAL FUNCTION GLOCKC(CDU2)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 CDU2, GLOCK
      PARAMETER (GLOCK=85.D0)
      GLOCKC = DABS(CDU2) .GT. GLOCK
      RETURN
      END
