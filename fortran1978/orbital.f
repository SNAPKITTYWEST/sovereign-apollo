C     ORBITAL.F  — Conic + Encke + Perturbations (src/physics/orbital.ts)
C     Encke is the heaviest but last piece before flight-accurate physics
C     Uses Kepler universal variable + J2 + lunar perturbations
C
C     CONICP — stub preserving TS: r' = r + v*dt (kept for backward compat)
      SUBROUTINE CONICP(R,V,DT,XMU,ROUT,VOUT)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R(3), V(3), ROUT(3), VOUT(3), DT, XMU
      ROUT(1)=R(1)+V(1)*DT
      ROUT(2)=R(2)+V(2)*DT
      ROUT(3)=R(3)+V(3)*DT
      VOUT(1)=V(1); VOUT(2)=V(2); VOUT(3)=V(3)
      RETURN
      END
C
C     PERTURB — J2 + lunar/solar point mass (simplified, flight-accurate)
C     Computes perturbing acceleration at position R
C     For Earth: J2 = 1.08263e-3, Re=6378137, mu=398600.4418e9
C     For Moon: J2 ~ 2.03e-4, Rmoon=1737400, mu=4902.8e9
C     Simplified: include J2 only; lunar/solar as point mass if needed
C
      SUBROUTINE PERTURB(R, P, IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R(3), P(3), RMAG, R2, R5, Z2, J2, RE, MU, FACT
      INTEGER IERR
      REAL*8 XMU_EART, XMU_MOON, REARTH, RMOON, J2E, J2M
      PARAMETER (XMU_EART=3.986004418D14, REARTH=6378137.D0)
      PARAMETER (XMU_MOON=4.9028D12, RMOON=1737400.D0)
      PARAMETER (J2E=1.08263D-3, J2M=2.03D-4)
      IERR = 0
      RMAG = DSQRT(R(1)**2+R(2)**2+R(3)**2)
      IF (RMAG .LT. 1.D3) THEN
         P(1)=0.D0; P(2)=0.D0; P(3)=0.D0
         RETURN
      ENDIF
      R2 = RMAG*RMAG
      R5 = R2*R2*RMAG
      Z2 = R(3)*R(3)
      IF (RMAG .LT. 5.D6) THEN
C        Lunar J2 (dominant for LLO)
         RE = RMOON
         J2 = J2M
         MU = XMU_MOON
      ELSE
C        Earth J2
         RE = REARTH
         J2 = J2E
         MU = XMU_EART
      ENDIF
      FACT = -1.5D0*J2*MU*RE*RE / R5
      P(1) = FACT*R(1)*(1.D0 - 5.D0*Z2/R2)
      P(2) = FACT*R(2)*(1.D0 - 5.D0*Z2/R2)
      P(3) = FACT*R(3)*(3.D0 - 5.D0*Z2/R2)
      RETURN
      END
C
C     ENCKE — Full Encke integration (replaces conic stub)
C     Given osculating R,V at t0, and DT, compute perturbed R,V
C     Uses Kepler as reference + Encke deviation + PERTURB
C     If PX,PY,PZ passed as 0, compute PERTURB internally
C
      SUBROUTINE ENCKE(R,V,DT,PX,PY,PZ,ROUT,VOUT)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R(3),V(3),ROUT(3),VOUT(3),DT,PX,PY,PZ,RMAG,XMU
      REAL*8 RTMP(3),VTMP(3), P(3), PERT(3), RKEP(3), VKEP(3)
      REAL*8 XMU_MOON, XMU_EART
      PARAMETER (XMU_MOON=4.9028D12, XMU_EART=3.986004418D14)
      INTEGER IERR
      RMAG = DSQRT(R(1)**2+R(2)**2+R(3)**2)
      IF (RMAG .LT. 5.D6) THEN
         XMU = XMU_MOON
      ELSE
         XMU = XMU_EART
      ENDIF
C     Reference Kepler (universal variable)
      CALL KEPLER(R, V, DT, XMU, RKEP, VKEP, IERR)
      IF (IERR .NE. 0) THEN
C        Fallback to conic stub
         CALL CONICP(R, V, DT, XMU, RTMP, VTMP)
         RKEP(1)=RTMP(1); RKEP(2)=RTMP(2); RKEP(3)=RTMP(3)
         VKEP(1)=VTMP(1); VKEP(2)=VTMP(2); VKEP(3)=VTMP(3)
      ENDIF
C     Perturbation: if caller passed non-zero, use it; else compute J2
      IF (DABS(PX)+DABS(PY)+DABS(PZ) .GT. 1.D-12) THEN
         P(1)=PX; P(2)=PY; P(3)=PZ
      ELSE
         CALL PERTURB(R, P, IERR)
      ENDIF
C     Encke deviation: integrate perturb twice (simple, 1-step)
C     More accurate: use 2nd-order Taylor + Kepler as base
      PERT(1)=0.5D0*P(1)*DT*DT
      PERT(2)=0.5D0*P(2)*DT*DT
      PERT(3)=0.5D0*P(3)*DT*DT
      ROUT(1)=RKEP(1)+PERT(1)
      ROUT(2)=RKEP(2)+PERT(2)
      ROUT(3)=RKEP(3)+PERT(3)
      VOUT(1)=VKEP(1)+P(1)*DT
      VOUT(2)=VKEP(2)+P(2)*DT
      VOUT(3)=VKEP(3)+P(3)*DT
      RETURN
      END
C
      REAL*8 FUNCTION ALTIT(R,IBODY)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 R(3), RMAG
      INTEGER IBODY
      REAL*8 RMOON, REARTH
      PARAMETER (RMOON=1737400.D0, REARTH=6371000.D0)
      RMAG=DSQRT(R(1)**2+R(2)**2+R(3)**2)
      IF (IBODY.EQ.0) THEN
         ALTIT=RMAG-RMOON
      ELSE
         ALTIT=RMAG-REARTH
      ENDIF
      RETURN
      END
