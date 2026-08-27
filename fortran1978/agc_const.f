C     AGC_CONST.F  — ISA constants  (src/agc/isa.ts)
C     Timing MCT per opcode (DOCUMENTED) — BLOCK DATA only
      BLOCK DATA AGCDTA
      INTEGER ITIMTC
      COMMON /AGCTIM/ ITIMTC(0:15)
      DATA ITIMTC/1,2,2,2,2,2,2,2,1,2,2,3,2,2,3,6/
      END
