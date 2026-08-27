C     MAIN.F  — Deterministic Mission Loop Program  (src/mission/replay-cli.ts)
C     Explicit control flow per Phase 5 — no callbacks, no promises
      PROGRAM SOVAPOL
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER IMETSC, IMETH, IVEH, IGUID, IENG, IENGON, ICOMM
      INTEGER IALARM, IPHASE, NEVENT, CURSOR, NHASH, ICHASH
      INTEGER IVERB, INOUN, IERR, NWORDS, N, IMATCH
      INTEGER IMETEV, IVEHEV, IGUIDV, ICOMMV, IALRMV
      CHARACTER*9 CMET, CMETEV
      CHARACTER*40 CEVENT
      REAL*8 POS, VEL, AMASS, AMDRY, CDU, THRUST, ISP, THROTT
      REAL*8 GMOON
      PARAMETER (GMOON=1.62D0)
      COMMON /MSTATE/ IMETSC, IMETH(3), IVEH, IGUID, IENG, THRUST,
     *                ISP, THROTT, IENGON, ICOMM, POS(3), VEL(3),
     *                AMASS, AMDRY, CDU(3), IALARM, IPHASE(8)
      COMMON /MSTATC/ CMET
      COMMON /TIMELN/ NEVENT, IMETEV(22), IVEHEV(22), IGUIDV(22),
     *                ICOMMV(22), IALRMV(22)
      COMMON /TIMECT/ CMETEV(22), CEVENT(22)
      COMMON /REPLAY/ CURSOR, NHASH, ICHASH
      INTEGER IARGS, IARGC
C     --- INIT ---
      CALL TELINI
      CALL REPINI
C     Load timeline; fallback to built-in if file missing
      CALL LDTIML('fortran1978/mission_timeline.txt', IERR)
      IF (IERR.NE.0) THEN
         CALL LDTIML('mission_timeline.txt', IERR)
         IF (IERR.NE.0) THEN
            WRITE(6,*) 'WARN: timeline file not found, using BLKDTA'
            NEVENT=22
         ENDIF
      ENDIF
      OPEN(UNIT=11, FILE='replay_out.txt', STATUS='UNKNOWN', ERR=90)
      WRITE(6,*) 'SOVEREIGN APOLLO 1978 FORTRAN SIMULATOR'
      WRITE(6,*) 'NEVENT=', NEVENT
C     --- MISSION LOOP (explicit, deterministic) ---
      CURSOR=0
 10   CONTINUE
      IF (CURSOR .GE. NEVENT) GOTO 20
C     LOAD CANONICAL STATE FROM TIMELINE (replaces eventsToStates)
      CALL EVTOST(CURSOR+1)
C     READ INPUT (replaces Dsky.key → dispatchVerb event)
      CALL RDINPT(IVERB, INOUN, IERR)
      IF (IVERB.EQ.37) THEN
         CALL DSPV37(INOUN, CMET)
         IGUID=INOUN
      ENDIF
C     UPDATE GUIDANCE (throttle + DAP) — Servicer 2-s tick inside ENGSTP handles phase
C     For PDI phases compute throttle from stub aCmd=5.0 m/s2
      IF (IGUID.EQ.63 .OR. IGUID.EQ.64) THEN
         THROTT = THROTC(5.D0, 0.D0, AMASS)
      ENDIF
C     UPDATE NAVIGATION (conic stub)
C     (orbital propagation would be here; stub preserves TS)
C     UPDATE VEHICLE (physics tick)
      CALL ENGSTP(1.D0, IERR)
C     UPDATE TELEMETRY (frame + comms)
      CALL BFRAME(IMETSC, IGUID, NWORDS, IERR)
      CALL COMUPD(1, -80.D0, ICOMM, IERR)
C     WRITE STATE (fixed-format, replaces JSON + SHA chain)
      CALL WRSTATE(11, IERR)
C     INVARIANT CHECK (replaces throw)
      CALL ASSINV(IERR)
      IF (IERR.NE.0) THEN
         IALARM = 1202
         WRITE(6,'(A,I4,A,I8)') ' INVARIANT FAIL IERR=',IERR,' MET=',IMETSC
      ENDIF
C     NEXT TICK (replaces callback scheduling)
      CURSOR = CURSOR + 1
C     Fault-injection hook: if CURSOR==12 (PDI 1202) inject overflow automatically for demo
      IF (CURSOR.EQ.11) THEN
         CALL FLTINS(0, IMETSC, 0.D0, IERR)
      ENDIF
      GOTO 10
 20   CONTINUE
      CALL WRSUMM(11)
      CLOSE(11)
      WRITE(6,*) 'REPLAY COMPLETE N=', CURSOR,' CHK=', ICHASH
C     Verify determinism second run
      CALL REPVFY(IMATCH)
      IF (IMATCH.EQ.1) WRITE(6,*) 'DETERMINISM OK'
      IF (IMATCH.EQ.0) WRITE(6,*) 'DETERMINISM FAIL'
      STOP
 90   WRITE(6,*) 'I/O ERROR OPEN replay_out.txt'
      STOP
      END
