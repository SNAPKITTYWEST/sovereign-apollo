C     AGC_INTERP.F  — Interpreter VM vector ops (src/agc/interpreter.ts)
      BLOCK DATA INTPAD
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 MPAC
      COMMON /IMPAC/ MPAC(7)
      DATA MPAC/7*0.D0/
      END
C     DOT = sum a_i b_i
      REAL*8 FUNCTION DOTF(A,B)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 A(3), B(3)
      DOTF = A(1)*B(1)+A(2)*B(2)+A(3)*B(3)
      RETURN
      END
C     UNIT = v/|v| ; guards |v|=0
      SUBROUTINE UNITV(V,U)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 V(3), U(3), VMAG
      VMAG = DSQRT(V(1)**2+V(2)**2+V(3)**2)
      IF (VMAG .EQ. 0.D0) THEN
         U(1)=0.D0; U(2)=0.D0; U(3)=0.D0
      ELSE
         U(1)=V(1)/VMAG; U(2)=V(2)/VMAG; U(3)=V(3)/VMAG
      ENDIF
      RETURN
      END
C     VXM = v^T M  (row-major per interpreter.ts; FORTRAN M column-major so transposed access preserves math)
      SUBROUTINE VXMF(V,M, R)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 V(3), M(3,3), R(3)
      R(1)=V(1)*M(1,1)+V(2)*M(2,1)+V(3)*M(3,1)
      R(2)=V(1)*M(1,2)+V(2)*M(2,2)+V(3)*M(3,2)
      R(3)=V(1)*M(1,3)+V(2)*M(2,3)+V(3)*M(3,3)
      RETURN
      END
      REAL*8 FUNCTION ABVALF(V)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 V(3)
      ABVALF = DSQRT(V(1)**2+V(2)**2+V(3)**2)
      RETURN
      END
C     Simplified exec dispatcher (VLOAD/VSU/VAD/DOT/UNIT/EXIT)
      SUBROUTINE INTPRC(NOPS, IOPS, ARGS, IERR)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER NOPS, IOPS(NOPS), IERR, I
      REAL*8 ARGS(3,NOPS), V(3), U(3), MPAC
      COMMON /IMPAC/ MPAC(7)
      IERR=0
      DO 10 I=1,NOPS
        IF (IOPS(I).EQ.1) THEN
C         VLOAD
          MPAC(1)=ARGS(1,I); MPAC(2)=ARGS(2,I); MPAC(3)=ARGS(3,I)
        ELSE IF (IOPS(I).EQ.2) THEN
C         VSU
          V(1)=MPAC(1)-ARGS(1,I); V(2)=MPAC(2)-ARGS(2,I); V(3)=MPAC(3)-ARGS(3,I)
          MPAC(1)=V(1); MPAC(2)=V(2); MPAC(3)=V(3)
        ELSE IF (IOPS(I).EQ.3) THEN
          V(1)=MPAC(1)+ARGS(1,I); V(2)=MPAC(2)+ARGS(2,I); V(3)=MPAC(3)+ARGS(3,I)
          MPAC(1)=V(1); MPAC(2)=V(2); MPAC(3)=V(3)
        ELSE IF (IOPS(I).EQ.4) THEN
          MPAC(1)=MPAC(1)*ARGS(1,I)+MPAC(2)*ARGS(2,I)+MPAC(3)*ARGS(3,I)
        ELSE IF (IOPS(I).EQ.5) THEN
          V(1)=MPAC(1); V(2)=MPAC(2); V(3)=MPAC(3)
          CALL UNITV(V,U)
          MPAC(1)=U(1); MPAC(2)=U(2); MPAC(3)=U(3)
        ELSE IF (IOPS(I).EQ.99) THEN
          RETURN
        ENDIF
 10   CONTINUE
      RETURN
      END
