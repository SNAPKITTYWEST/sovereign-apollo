C     FOREST_RUTH.F  — 4th-order symplectic integrator (Forest-Ruth 1990)
C     Replaces Euler stub in engine.f / orbital.f
C     Time-reversible, symplectic: energy drift is BOUNDED not secular.
C     Use for multi-revolution propagation where conservation matters.
C
C     Coefficients (exact from Forest & Ruth 1990):
C       THETA = 1.35120719195965764  (primary drift/kick weight)
C       XI    = 1 - 2*THETA = -1.70241438391931528  (middle kick)
C       C1=C4 = THETA/2   (outer drift fractions)
C       C2=C3 = (1-THETA)/2  (inner drift fractions)
C       D1=D3 = THETA        (outer kicks)
C       D2    = XI           (middle kick)
C
C     Compile: gfortran -std=legacy -c forest_ruth.f
C
      SUBROUTINE FRSTEP(R, V, DT, PERT, ROUT, VOUT)
C     One Forest-Ruth step.  PERT = external acceleration (m/s^2, 3-vector).
C     Pass PERT = 0,0,0 for pure Keplerian.
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R(3), V(3), DT, PERT(3), ROUT(3), VOUT(3)
      REAL*8 RI(3), VI(3), A(3)
      REAL*8 THETA, C1, C2, D1, D2, XI
      REAL*8 XMU_EART, XMU_MOON
      PARAMETER (THETA=1.35120719195965764D0)
      PARAMETER (XMU_EART=3.986004418D14, XMU_MOON=4.9028D12)
      INTEGER K

      C1 = 0.5D0 * THETA
      C2 = 0.5D0 * (1.D0 - THETA)
      D1 = THETA
      D2 = 1.D0 - 2.D0*THETA
      DO 10 K=1,3
         RI(K) = R(K)
         VI(K) = V(K)
  10  CONTINUE

C     Stage 1: drift C1
      DO 20 K=1,3
         RI(K) = RI(K) + C1*DT*VI(K)
  20  CONTINUE
      CALL GRAV(RI, PERT, A)
C     Kick D1
      DO 25 K=1,3
         VI(K) = VI(K) + D1*DT*A(K)
  25  CONTINUE
C     Stage 2: drift C2
      DO 30 K=1,3
         RI(K) = RI(K) + C2*DT*VI(K)
  30  CONTINUE
      CALL GRAV(RI, PERT, A)
C     Kick D2  (middle kick — negative for FR coefficients)
      DO 35 K=1,3
         VI(K) = VI(K) + D2*DT*A(K)
  35  CONTINUE
C     Stage 3: drift C3 = C2
      DO 40 K=1,3
         RI(K) = RI(K) + C2*DT*VI(K)
  40  CONTINUE
      CALL GRAV(RI, PERT, A)
C     Kick D3 = D1
      DO 45 K=1,3
         VI(K) = VI(K) + D1*DT*A(K)
  45  CONTINUE
C     Stage 4: final drift C4 = C1
      DO 50 K=1,3
         ROUT(K) = RI(K) + C1*DT*VI(K)
         VOUT(K) = VI(K)
  50  CONTINUE
      RETURN
      END
C
C     GRAV — Gravitational acceleration + perturbation at R
      SUBROUTINE GRAV(R, PERT, A)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R(3), PERT(3), A(3), RMAG, R3
      REAL*8 XMU_EART, XMU_MOON, XMU
      PARAMETER (XMU_EART=3.986004418D14, XMU_MOON=4.9028D12)
      INTEGER K
      RMAG = DSQRT(R(1)**2+R(2)**2+R(3)**2)
      IF (RMAG .LT. 5.D6) THEN
         XMU = XMU_MOON
      ELSE
         XMU = XMU_EART
      ENDIF
      R3 = RMAG*RMAG*RMAG
      DO 10 K=1,3
         A(K) = -XMU*R(K)/R3 + PERT(K)
  10  CONTINUE
      RETURN
      END
C
C     FRPROP — Multi-step Forest-Ruth propagation over time T
C     Subdivides into NSTEP steps of DT = T/NSTEP.
C     NSTEP default: ceil(T / 60.0) — 1-minute substeps for LEO.
      SUBROUTINE FRPROP(R0, V0, T, PERT, RFIN, VFIN, NSTEP)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R0(3), V0(3), T, PERT(3), RFIN(3), VFIN(3)
      REAL*8 RTMP(3), VTMP(3), DT
      INTEGER NSTEP, I, K
      IF (NSTEP .LE. 0) NSTEP = MAX(1, INT(DABS(T)/60.D0) + 1)
      DT = T / DBLE(NSTEP)
      DO 5 K=1,3
         RTMP(K) = R0(K)
         VTMP(K) = V0(K)
    5 CONTINUE
      DO 100 I=1,NSTEP
         CALL FRSTEP(RTMP, VTMP, DT, PERT, RFIN, VFIN)
         DO 10 K=1,3
            RTMP(K) = RFIN(K)
            VTMP(K) = VFIN(K)
   10    CONTINUE
  100 CONTINUE
      RETURN
      END
