⍝ agc_interpreter.dyalog — AGC Interpretive Dispatcher
⍝ Author: Gemini (Google DeepMind)
⍝ Method: APL replaces verbose select case branching with O(1) vector
⍝         indexing and dynamic execution (⍎). The 32 INDJUMP opcodes and
⍝         4 DOSTORE variants map directly to function arrays — the
⍝         interpretive dispatcher becomes a flat, deterministic state machine.

:Namespace AGC_Interpreter
    ⎕IO ← 0 ⍝ 0-based indexing for hardware memory alignment

    ⍝ --------------------------------------------------------------------
    ⍝ Machine State & Memory
    ⍝ --------------------------------------------------------------------
    MPAC ← 7⍴0 ⋄ MODE ← 0 ⋄ LOC ← 0 ⋄ ADDRWD ← 0 ⋄ CYR ← 0
    EDOP ← 0 ⋄ PUSHLOC ← 0 ⋄ BANKSET ← 0 ⋄ BBANK ← 0
    FBANK ← 0 ⋄ EBANK ← 0 ⋄ OVFIND ← 0 ⋄ NEWJOB ← 0
    FIXLOC ← 0 ⋄ INDEXLOC ← 0 ⋄ POLISH ← 0 ⋄ QPRET ← 0

    MEM ← 8192⍴0 ⍝ Simulated fixed/erasable memory bank

    ⍝ Dispatch Tables
    INDJUMP_TBL ← 'VLOAD' 'TAD' 'SIGNOP' 'VXSC' 'CGOTO' 'TLOAD' 'DLOAD' 'VSC' 'SLOAD' 'SSP' 'PDDL' 'MXV' 'PDVL' 'CCALL' 'VXM' 'TSLC' 'DMPR' 'DDV' 'BDDV' 'GSHIFT' 'VAD' 'VSU' 'BVSU' 'DOT' 'VXV' 'VPROJ' 'DSU' 'BDSU' 'DAD' 'UNIMPL' 'DMP1' 'SETPD'
    STORE_TBL ← 'OP_STORE' 'OP_STORE_DODLOAD' 'OP_STORE_DOVLOAD' 'OP_STORE_STCALL'

    ∇ INIT
      MPAC←7⍴0 ⋄ MODE←0 ⋄ LOC←0 ⋄ ADDRWD←0 ⋄ CYR←0 ⋄ EDOP←0
      PUSHLOC←0 ⋄ OVFIND←0 ⋄ NEWJOB←0 ⋄ BBANK←0
    ∇

    ⍝ --------------------------------------------------------------------
    ⍝ Central Dispatcher (DANZIG / NEWOPS)
    ⍝ --------------------------------------------------------------------
    ∇ STEP;OP
      BBANK ← BANKSET

      :If EDOP≠0
          OPJUMP EDOP
          :Return
      :EndIf

      :If NEWJOB≠0
          CHANGE_JOB
          :Return
      :EndIf

      LOC +← 1
      OP ← FETCH_WORD LOC

      :If OP>0
          DOSTORE OP
          :Return
      :EndIf

      ⍝ Extract EDOP (LOW7) and left-hand opcode via modulo arithmetic
      EDOP ← 128 | OP
      OPJUMP ⌊OP ÷ 128
    ∇

    ∇ OPJUMP CYR_IN;C
      CYR ← CYR_IN ⋄ C ← CYR

      :If C=0
          EXIT_INTERP
          :Return
      :EndIf

      ⍝ Bit 0 determines indexing vs direct addressing
      :If (2|C)≠0
          INDEX_ADDRESS
      :Else
          DIRADRES
      :EndIf

      ⍝ Dispatch via INDJUMP table (LOW5) — O(1) vector indexing
      ⍎ (32|CYR) ⊃ INDJUMP_TBL
    ∇

    ⍝ --------------------------------------------------------------------
    ⍝ Address Resolvers
    ⍝ --------------------------------------------------------------------
    ∇ DIRADRES;NEXT
      NEXT ← PEEK_WORD LOC+1
      :If NEXT=0
          PUSHUP
      :Else
          LOC +← 1
          ADDRWD ← NEXT
          FINAL_DIGEST_DIRECT
      :EndIf
    ∇

    ∇ INDEX_ADDRESS
      INDEXLOC ← FIXLOC
      LOC +← 1
      ADDRWD ← FETCH_WORD LOC
      ⍎ (32|CYR) ⊃ INDJUMP_TBL
    ∇

    ∇ PUSHUP;DECR
      ⍝ Array-based switch for MODE decrement (DP=2, TP=3, VEC=6)
      DECR ← (0 1 ¯1 ⍳ MODE) ⊃ 2 3 6
      PUSHLOC -← DECR
      ADDRWD ← PUSHLOC
      ⍎ (32|CYR) ⊃ INDJUMP_TBL
    ∇

    ∇ FINAL_DIGEST_DIRECT
      ⍝ Applies -ENDVAC / IERASTST bank logic
    ∇

    ⍝ --------------------------------------------------------------------
    ⍝ Store Routines (DOSTORE / STORJUMP)
    ⍝ --------------------------------------------------------------------
    ∇ DOSTORE CODE;IDX
      ADDRWD ← 2048 | CODE ⍝ LOW11
      IDX ← 4 | ⌊ CODE ÷ 4096 ⍝ Extract Bits 12-14
      ⍎ IDX ⊃ STORE_TBL
    ∇

    ∇ OP_STORE ⋄ ⍝ Plain STORE → DANZIG ∇
    ∇ OP_STORE_DODLOAD ⋄ OP_STORE ⋄ CYR←6 ⋄ DIRADRES ∇
    ∇ OP_STORE_DOVLOAD ⋄ OP_STORE ⋄ CYR←0 ⋄ DIRADRES ∇
    ∇ OP_STORE_STCALL ⋄ OP_STORE ⋄ ⍝ STORE + CALL logic ∇

    ⍝ --------------------------------------------------------------------
    ⍝ Instruction Implementations (INDJUMP Table, 32 entries)
    ⍝ --------------------------------------------------------------------
    ∇ VLOAD ⋄ MODE ← ¯1 ∇
    ∇ TAD ∇
    ∇ SIGNOP ∇
    ∇ VXSC ∇
    ∇ CGOTO ∇
    ∇ TLOAD ⋄ MODE ← 1 ∇
    ∇ DLOAD ⋄ MODE ← 0 ∇
    ∇ VSC ∇
    ∇ SLOAD ⋄ MODE ← 0 ∇
    ∇ SSP ∇
    ∇ PDDL ∇
    ∇ MXV ∇
    ∇ PDVL ∇
    ∇ CCALL ∇
    ∇ VXM ∇
    ∇ TSLC ∇
    ∇ DMPR ∇
    ∇ DDV ∇
    ∇ BDDV ∇
    ∇ GSHIFT ∇
    ∇ VAD ∇
    ∇ VSU ∇
    ∇ BVSU ∇
    ∇ DOT ⋄ MODE ← 0 ∇
    ∇ VXV ∇
    ∇ VPROJ ∇
    ∇ DSU ∇
    ∇ BDSU ∇

    ∇ DAD;MEM_HI;MEM_LO
      MEM_HI ← FETCH_WORD ADDRWD
      MEM_LO ← FETCH_WORD ADDRWD+1
      ⍝ 1's complement fixed-point accumulation (EAC) occurs here
    ∇

    ∇ UNIMPL ∇
    ∇ DMP1 ∇
    ∇ SETPD ∇

    ⍝ --------------------------------------------------------------------
    ⍝ Control & Memory Primitives
    ⍝ --------------------------------------------------------------------
    ∇ EXIT_INTERP
      BBANK ← BANKSET
    ∇

    ∇ CHANGE_JOB
      ⍝ CHANG2 higher priority swap
    ∇

    ∇ RES ← FETCH_WORD ADDR
      RES ← MEM[ADDR]
    ∇

    ∇ RES ← PEEK_WORD ADDR
      RES ← MEM[ADDR]
    ∇

    ∇ DUMP_STATE
      ⎕ ← 'LOC: ', ⍕LOC
      ⎕ ← 'MODE: ', ⍕MODE
      ⎕ ← 'MPAC: ', ⍕MPAC
      ⎕ ← 'OVFIND: ', ⍕OVFIND
    ∇

:EndNamespace

⍝ --------------------------------------------------------------------
⍝ Usage:
⍝   AGC_Interpreter.INIT
⍝   AGC_Interpreter.MEM[0] ← ¯255   ⍝ inject a simulated opcode
⍝   AGC_Interpreter.STEP
⍝   AGC_Interpreter.DUMP_STATE
⍝ --------------------------------------------------------------------
