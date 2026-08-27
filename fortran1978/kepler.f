C     KEPLER.F  — Stumpff C(z)/S(z), TIMETHET, Lambert P38/P39
C     Implements universal variable formulation (Battin, Bate) in FORTRAN 77
C     Stumpff functions are the bodies Ahmad referenced as "already there"
C     This file closes them with Newton-Raphson bodies per spec step 2
C
C     Compile: gfortran -std=legacy -c kepler.f
C
C     C(z) = (1 - cos(sqrt(z)))/z    for z>0
C          = (cosh(sqrt(-z))-1)/(-z) for z<0
C          = 1/2  for z=0 (series)
C     S(z) = (sqrt(z)-sin(sqrt(z)))/sqrt(z)^3  for z>0
C          = (sinh(sqrt(-z))-sqrt(-z))/sqrt(-z)^3 for z<0
C          = 1/6  for z=0
C
      SUBROUTINE STUMPFF(Z, C, S)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 Z, C, S, RZ, Z2, Z3, Z4
      REAL*8 SZ, CZ
      IF (DABS(Z) .LT. 1.D-6) THEN
C        Series for small z: C=1/2 - z/24 + z^2/720 - z^3/40320 ...
C                           S=1/6 - z/120 + z^2/5040 - z^3/362880 ...
         Z2 = Z*Z
         Z3 = Z2*Z
         Z4 = Z3*Z
         C = 0.5D0 - Z/24.D0 + Z2/720.D0 - Z3/40320.D0 + Z4/3628800.D0
         S = 1.D0/6.D0 - Z/120.D0 + Z2/5040.D0 - Z3/362880.D0
     *       + Z4/39916800.D0
      ELSE IF (Z .GT. 0.D0) THEN
         RZ = DSQRT(Z)
         CZ = DCOS(RZ)
         SZ = DSIN(RZ)
         C = (1.D0 - CZ)/Z
         S = (RZ - SZ)/(RZ*RZ*RZ)
      ELSE
         RZ = DSQRT(-Z)
         CZ = DCOSH(RZ)
         SZ = DSINH(RZ)
         C = (CZ - 1.D0)/(-Z)
         S = (SZ - RZ)/(RZ*RZ*RZ)
      ENDIF
      RETURN
      END
C
C     TIMETHET — Time of flight for universal variable z
C     Given r1=|R1|, r2=|R2|, A, z, mu  →  dt
C     A = sign(sin(dnu))*sqrt(r1*r2*(1+cos(dnu)))  (Bate)
C     y(z) = r1 + r2 + A*(z*S -1)/sqrt(C)
C     x(z) = sqrt(y/C)
C     dt = (x^3*S + A*sqrt(y))/sqrt(mu)
C
      SUBROUTINE TIMETHET(R1, R2, A, Z, MU, DT, Y, IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R1, R2, A, Z, MU, DT, Y, C, S, X, SQTC, SQY
      INTEGER IERR
      REAL*8 R1R2
      IERR = 0
      CALL STUMPFF(Z, C, S)
      IF (C .LE. 0.D0) THEN
         IERR = 1
         DT = 0.D0
         Y = 0.D0
         RETURN
      ENDIF
      SQTC = DSQRT(C)
      Y = R1 + R2 + A*(Z*S - 1.D0)/SQTC
      IF (Y .LT. 0.D0) THEN
         IERR = 2
         DT = 0.D0
         RETURN
      ENDIF
      SQY = DSQRT(Y)
      X = SQY / SQTC
      DT = (X*X*X*S + A*SQY)/DSQRT(MU)
      RETURN
      END
C
C     LAMBERT — Solve Lambert targeting (P38/P39) via universal variable
C     Given R1(3), R2(3), DT, MU → V1(3), V2(3)
C     Uses Newton-Raphson on z to match dt = TIMETHET(z)
C     Returns IERR 0 ok, 1 no convergence, 2 geometry
C
      SUBROUTINE LAMBERT(R1, R2, DT, MU, V1, V2, IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R1(3), R2(3), V1(3), V2(3), DT, MU
      REAL*8 R1MAG, R2MAG, DOT, COSDNU, SINDNU, DNU, A
      REAL*8 Z, ZOLD, DTZ, DDTZ, C, S, Y, YOLD, X, XP, F, DF
      REAL*8 F1, F2, G, GS, G1, G2, H, DUM
      INTEGER IERR, ITER
      REAL*8 R1R2, TOL
      PARAMETER (TOL=1.D-8)
      IERR = 0
      R1MAG = DSQRT(R1(1)**2 + R1(2)**2 + R1(3)**2)
      R2MAG = DSQRT(R2(1)**2 + R2(2)**2 + R2(3)**2)
      DOT = R1(1)*R2(1) + R1(2)*R2(2) + R1(3)*R2(3)
      COSDNU = DOT/(R1MAG*R2MAG)
      IF (COSDNU .GT. 1.D0) COSDNU = 1.D0
      IF (COSDNU .LT. -1.D0) COSDNU = -1.D0
C     Use short-way (prograde) sin positive; for Apollo TLI use 0<dnu<pi
      SINDNU = DSQRT(1.D0 - COSDNU*COSDNU)
C     For transfer angle > pi, SINDNU negative (not needed for P38)
      A = SINDNU*DSQRT(R1MAG*R2MAG/(1.D0 + COSDNU))
      IF (DABS(A) .LT. 1.D-10) THEN
         IERR = 2
         RETURN
      ENDIF
C     Initial z guess: 0 (parabolic)
      Z = 0.D0
      DO 100 ITER=1,40
         CALL TIMETHET(R1MAG, R2MAG, A, Z, MU, DTZ, Y, IERR)
         IF (IERR .NE. 0) THEN
            Z = Z*0.5D0
            GOTO 100
         ENDIF
         F = DTZ - DT
         IF (DABS(F) .LT. TOL) GOTO 110
C        Numerical derivative dF/dz
         CALL STUMPFF(Z, C, S)
         CALL STUMPFF(Z+1.D-6, F1, F2)
         CALL TIMETHET(R1MAG, R2MAG, A, Z+1.D-6, MU, DUM, YOLD, IERR)
         IF (IERR .NE. 0) DUM = DTZ
         DDTZ = (DUM - DTZ)/1.D-6
         IF (DABS(DDTZ) .LT. 1.D-12) DDTZ = 1.D-12
         ZOLD = Z
         Z = Z - F/DDTZ
C        Damp large steps
         IF (DABS(Z-ZOLD) .GT. 5.D0) Z = ZOLD - DSIGN(5.D0, F/DDTZ)
 100  CONTINUE
      IERR = 1
      RETURN
 110  CONTINUE
C     Converged z → compute Lagrange f,g and velocities
      CALL STUMPFF(Z, C, S)
      CALL TIMETHET(R1MAG, R2MAG, A, Z, MU, DTZ, Y, IERR)
      X = DSQRT(Y/C)
C     Lagrange coefficients
      F = 1.D0 - X*X/R1MAG*C
      G = DTZ - X*X*X/DSQRT(MU)*S
      GST = 1.D0 - X*X/R2MAG*C
C     V1 = (R2 - F*R1)/G
C     V2 = (GST*R2 - R1)/G   (Battin form)
      IF (DABS(G) .LT. 1.D-10) THEN
         IERR = 2
         RETURN
      ENDIF
      V1(1) = (R2(1) - F*R1(1))/G
      V1(2) = (R2(2) - F*R1(2))/G
      V1(3) = (R2(3) - F*R1(3))/G
      V2(1) = (GST*R2(1) - R1(1))/G
      V2(2) = (GST*R2(2) - R1(2))/G
      V2(3) = (GST*R2(3) - R1(3))/G
      RETURN
      END
C
C     KEPLER — Universal variable propagation
C     Given R0,V0,DT,MU → R,V
C     Solves Kepler's equation via Newton-Raphson on chi
C
      SUBROUTINE KEPLER(R0, V0, DT, MU, R, V, IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R0(3), V0(3), R(3), V(3), DT, MU
      REAL*8 R0MAG, V0MAG, R0DOTV, ALPHA, CHI, Z, C, S
      REAL*8 RVAL, F, G, FDOT, GDOT, DTCHI, DDTCHI
      REAL*8 SQMU, CH2, CH3
      REAL*8 PI, PERIOD, CHIREV, DTREM, CHIHI, CHILO
      INTEGER IERR, ITER, NREV
      LOGICAL DOBIS
      REAL*8 TOL
      PARAMETER (TOL=1.D-8)
      IERR = 0
      R0MAG = DSQRT(R0(1)**2+R0(2)**2+R0(3)**2)
      V0MAG = DSQRT(V0(1)**2+V0(2)**2+V0(3)**2)
      R0DOTV = R0(1)*V0(1)+R0(2)*V0(2)+R0(3)*V0(3)
      ALPHA = 2.D0/R0MAG - V0MAG*V0MAG/MU
      SQMU = DSQRT(MU)
C     Initial chi: period-based for elliptic; linear for others
C     For elliptic (alpha>0): chi_0 = chi_period * (dt mod T + nrev*T) / T
C     where chi_period = 2*pi/sqrt(alpha)  and  T = 2*pi/(alpha^1.5 * sqrt(mu))
C     This puts chi_0 right on top of the correct root for circular/LEO.
      PI = 4.D0*DATAN(1.D0)
      IF (ALPHA .GT. 1.D-10) THEN
         PERIOD = 2.D0*PI / (ALPHA**1.5D0 * SQMU)
         NREV   = INT(DT / PERIOD)
         DTREM  = DT - NREV * PERIOD
         IF (DTREM .LT. 0.D0) THEN
            NREV = NREV - 1
            DTREM = DTREM + PERIOD
         ENDIF
         CHIREV = 2.D0*PI / DSQRT(ALPHA)
         CHI = CHIREV * (DTREM/PERIOD + DBLE(NREV))
      ELSE
         CHI = SQMU*DT / R0MAG
      ENDIF
C     Bisection bracket (tracks sign of F for fallback)
      CHIHI = 0.D0
      CHILO = 0.D0
      DOBIS = .FALSE.
      DO 200 ITER=1,100
         Z = ALPHA*CHI*CHI
         CALL STUMPFF(Z, C, S)
         RVAL = CHI*CHI*C + R0DOTV/SQMU*CHI*(1.D0 - Z*S)
     *          + R0MAG*(1.D0 - Z*C)
C        Time equation: sqrt(mu)*t = chi^3*S + A*chi^2*C + r0*chi*(1 - z*S)
         DTCHI = CHI*CHI*CHI*S + R0DOTV/SQMU*CHI*CHI*C
     *           + R0MAG*CHI*(1.D0 - Z*S)
         F = DTCHI - SQMU*DT
         IF (DABS(F) .LT. TOL) GOTO 210
C        Update bisection bracket
         IF (F .GT. 0.D0) THEN
            IF (.NOT. DOBIS .OR. CHI .LT. CHIHI) CHIHI = CHI
         ELSE
            IF (.NOT. DOBIS .OR. CHI .GT. CHILO) CHILO = CHI
         ENDIF
         IF (CHIHI .GT. 0.D0 .AND. CHILO .GT. 0.D0) DOBIS = .TRUE.
C        Newton step
         DDTCHI = RVAL
         IF (DABS(DDTCHI) .LT. 1.D-10) DDTCHI = 1.D-10
         CH2 = CHI - F/DDTCHI
C        Bisection fallback: if Newton leaves bracket or bracket exists
         IF (DOBIS) THEN
            IF (CH2 .LE. CHILO .OR. CH2 .GE. CHIHI) THEN
               CH2 = 0.5D0*(CHILO + CHIHI)
            ENDIF
         ENDIF
         IF (DABS(CH2-CHI) .LT. TOL) THEN
            CHI = CH2
            GOTO 210
         ENDIF
         CHI = CH2
 200  CONTINUE
      IERR = 1
      RETURN
 210  CONTINUE
      Z = ALPHA*CHI*CHI
      CALL STUMPFF(Z, C, S)
      F = 1.D0 - CHI*CHI/R0MAG*C
      G = DT - CHI*CHI*CHI/SQMU*S
      R(1) = F*R0(1) + G*V0(1)
      R(2) = F*R0(2) + G*V0(2)
      R(3) = F*R0(3) + G*V0(3)
      RVAL = DSQRT(R(1)**2+R(2)**2+R(3)**2)
      FDOT = -SQMU*CHI/RVAL/R0MAG*(1.D0 - Z*C)
      GDOT = 1.D0 - CHI*CHI/RVAL*C
      V(1) = FDOT*R0(1) + GDOT*V0(1)
      V(2) = FDOT*R0(2) + GDOT*V0(2)
      V(3) = FDOT*R0(3) + GDOT*V0(3)
      RETURN
      END
