C     TEST_KEPLER.F  — Verify Stumpff, TIMETHET, Lambert, Kepler
      PROGRAM TSTKEP
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      REAL*8 Z, C, S, R1(3), R2(3), V1(3), V2(3), DT, MU
      REAL*8 R0(3), V0(3), R(3), V(3)
      INTEGER IERR
      WRITE(6,*) 'Stumpff test:'
      CALL STUMPFF(0.D0, C, S)
      WRITE(6,*) ' Z=0 C=',C,' S=',S,' (exp 0.5, 0.1666)'
      CALL STUMPFF(1.D0, C, S)
      WRITE(6,*) ' Z=1 C=',C,' S=',S
      CALL STUMPFF(-1.D0, C, S)
      WRITE(6,*) ' Z=-1 C=',C,' S=',S
      WRITE(6,*) 'TIMETHET test:'
      CALL TIMETHET(6500000.D0, 6500000.D0, 6500000.D0, 0.D0,
     * 3.986004418D14, DT, R1(1), IERR)
      WRITE(6,*) ' TIMETHET IERR=',IERR,' DT=',DT
      WRITE(6,*) 'Lambert test: LEO to LEO 90deg 90min'
      R1(1)=6500000.D0; R1(2)=0.D0; R1(3)=0.D0
      R2(1)=0.D0; R2(2)=6500000.D0; R2(3)=0.D0
      DT=5400.D0
      MU=3.986004418D14
      CALL LAMBERT(R1,R2,DT,MU,V1,V2,IERR)
      WRITE(6,*) ' LAMBERT IERR=',IERR
      WRITE(6,*) '  V1=',V1(1),V1(2),V1(3)
      WRITE(6,*) '  V2=',V2(1),V2(2),V2(3)
      WRITE(6,*) 'Kepler test: circular LEO 1 orbit'
      R0(1)=6500000.D0; R0(2)=0.D0; R0(3)=0.D0
      V0(1)=0.D0; V0(2)=7800.D0; V0(3)=0.D0
      DT=5400.D0
      CALL KEPLER(R0,V0,DT,MU,R,V,IERR)
      WRITE(6,*) ' KEPLER IERR=',IERR
      WRITE(6,*) '  R=',R(1),R(2),R(3)
      WRITE(6,*) '  V=',V(1),V(2),V(3)
      WRITE(6,*) 'Encke test: same with J2'
      CALL ENCKE(R0,V0,DT,0.D0,0.D0,0.D0,R,V,IERR)
      WRITE(6,*) ' ENCKE IERR=',IERR
      WRITE(6,*) '  R=',R(1),R(2),R(3)
      STOP
      END
