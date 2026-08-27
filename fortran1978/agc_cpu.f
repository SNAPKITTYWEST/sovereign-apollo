C     AGC_CPU.F  — Fetch-decode-execute  (src/agc/cpu.ts)
      BLOCK DATA AGCPUD
      INTEGER A, L, Q, Z, BB, ICYC, IEXTND, INEXT, IDXVAL, IOVER
      COMMON /AGCCPU/ A, L, Q, Z, BB, ICYC, IEXTND, INEXT, IDXVAL, IOVER
      DATA A/0/, L/0/, Q/0/, Z/0/, BB/0/, ICYC/0/, IEXTND/0/
      DATA INEXT/0/, IDXVAL/0/, IOVER/0/
      END
C     AGCSTEP — one instruction at Z; IERR 0 ok, 1 unknown
      SUBROUTINE AGCSTEP(IERR)
      INTEGER A, L, Q, Z, BB, ICYC, IEXTND, INEXT, IDXVAL, IOVER
      INTEGER IERR, IWORD, IOP, IADDR, IEXT, IEFF, IMEM, ITMP
      INTEGER AGCRD, I15ADD, CHRD
      COMMON /AGCCPU/ A, L, Q, Z, BB, ICYC, IEXTND, INEXT, IDXVAL, IOVER
      IERR = 0
      IWORD = AGCRD(Z)
      Z = IAND(Z+1, 8191)
C     EXTEND prefix 000006 oct = 6 dec
      IF (IWORD .EQ. 6) THEN
         IEXTND = 1
         ICYC = ICYC + 1
         RETURN
      ENDIF
C     Decode: opcode = word>>12 & 7 ; addr = word & 07777 (simplified RECONSTRUCTED)
      IOP = IAND(ISHFT(IWORD,-9), 7)
      IADDR = IAND(IWORD, 4095)
C     INDEX handling (opcode 2)
      IF (IOP .EQ. 2) THEN
         IDXVAL = AGCRD(IADDR)
         INEXT = 1
         ICYC = ICYC + 2
         RETURN
      ENDIF
      IEFF = IADDR
      IF (INEXT .EQ. 1) THEN
         IEFF = IAND(IEFF + IDXVAL, 8191)
         INEXT = 0
      ENDIF
      IEXT = IEXTND
      IEXTND = 0
C     Dispatch (simplified; full table in isa.ts)
      IF (IOP .EQ. 0) THEN
C        TC
         Q = Z
         Z = IEFF
         ICYC = ICYC + 1
      ELSE IF (IOP .EQ. 1) THEN
C        CCS
         IMEM = AGCRD(IEFF)
         IF (IMEM .EQ. 0) THEN
            Z = Z + 1
         ELSE IF (IAND(IMEM,16384).EQ.0) THEN
            A = IAND(IMEM-1,32767)
         ELSE IF (IMEM .EQ. 32767) THEN
            Z = Z + 2
         ELSE
            A = IAND(NOT(IMEM),32767)
            Z = Z + 1
         ENDIF
         ICYC = ICYC + 2
      ELSE IF (IOP .EQ. 3) THEN
C        XCH
         ITMP = A
         A = AGCRD(IEFF)
         CALL AGCWR(IEFF,ITMP,IERR)
         ICYC = ICYC + 2
      ELSE IF (IOP .EQ. 4) THEN
         A = IAND(NOT(AGCRD(IEFF)),32767)
         ICYC = ICYC + 2
      ELSE IF (IOP .EQ. 5) THEN
         IF (A.EQ.15360 .OR. A.EQ.16384) IOVER=1
         CALL AGCWR(IEFF,A,IERR)
         ICYC = ICYC + 2
      ELSE IF (IOP .EQ. 6) THEN
         A = I15ADD(A, AGCRD(IEFF))
         ICYC = ICYC + 2
      ELSE
         IF (IEXT .EQ. 1) THEN
C           Extracode dispatch (subset)
            IF (IOP .EQ. 0) THEN
               A = CHRD(IEFF)
               ICYC = ICYC + 2
            ELSE IF (IOP .EQ. 1) THEN
               CALL CHWR(IEFF,A)
               ICYC = ICYC + 2
            ELSE IF (IOP .EQ. 4) THEN
               IMEM = AGCRD(IEFF)+1
               CALL AGCWR(IEFF,IAND(IMEM,32767),IERR)
               ICYC = ICYC + 2
            ELSE IF (IOP .EQ. 7) THEN
               A = AGCRD(IEFF)
               L = AGCRD(IAND(IEFF+1,8191))
               ICYC = ICYC + 3
            ELSE
               ICYC = ICYC + 2
            ENDIF
         ELSE
            A = IAND(A, AGCRD(IEFF))
            ICYC = ICYC + 2
         ENDIF
      ENDIF
      RETURN
      END
