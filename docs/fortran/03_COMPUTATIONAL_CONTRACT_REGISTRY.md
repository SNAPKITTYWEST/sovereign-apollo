# Computational-Contract Registry — TypeScript → FORTRAN Source Spec

> Each entry is the **source specification** for the FORTRAN port. Units, precision, determinism per Phase 2.

## 1. AGC Memory — `AgcMemory.add(a,b)`

```
Function: add
Purpose: 1's complement end-around carry addition (DOCUMENTED R-393)
Inputs: a INTEGER(0..32767) oct 0..77777, b INTEGER
Outputs: sum INTEGER masked 0..77777 (15 bits + 1 parity stripped)
Mutation: none
Side effects: none
Numerics: sum = (a & 077777) + (b & 077777); if carry 0100000 then sum = (sum & 077777)+1
Units: dimensionless AGC words
Precision: 15-bit integer (1's complement, -0 distinct)
Error: no throw; overflow retained for TS check later
Deps: none
Frequency: per AD/SU instruction (~100 Hz during burns)
Determinism: deterministic (pure)
FORTRAN: INTEGER FUNCTION I15ADD(IA,IB)  — see fortran1978/agc_memory.f

Equivalence: SEMANTICALLY EQUIVALENT (bit-identical)
```

## 2. AGC CPU — `AgcCpu.step()`

```
Function: step
Purpose: Fetch-decode-execute one AGC instruction, advancing Z
Inputs: mem.erasable[2048], mem.fixed[36k], state.{A,L,Q,Z,BB,cycles,extendNext,nextIndex}
Outputs: mutated state.{A,L,Q,Z,BB,cycles}, mem (on XCH/TS)
Mutation: A,L,Q,Z,BB,cycles, mem cells, channels
Side effects: channel I/O if READ/WRITE; overflow flag if TS 037777/040000
Numerics: TC/CCS/INDEX/CS/TS/AD/MASK + Extracode READ/WRITE/INCR/DCA/BZMF; INDEX adds offset & 07777; EXTEND prefix sets flag
Units: words / addresses octal
Precision: 15-bit; DC handled via END-AROUND
Error: throw if WRITE to fixed; FORTRAN → IERR=2
Deps: memory.read/write, decode, TIMING_MCT
Frequency: ~85 kHz MCT (simulated per-step, not real-time)
Determinism: deterministic
FORTRAN: SUBROUTINE AGCSTEP(IERR)  COMMON /AGCMEM/ + /AGCCPU/
```

## 3. Executive — `Executive.novac(priority,pc)`

```
Function: novac
Purpose: Allocate VAC area for new job by priority (DOCUMENTED EXECUTIVE.agc)
Inputs: priority INTEGER 0..6 (0 highest), pc INTEGER address
Outputs: Job {id,priority,pc,vacArea,phase} or ExecOverflowError code 1202
Mutation: jobs sorted by priority
Side effects: if jobs>=8 → overflow (1202 alarm before throw)
Numerics: none (queue logic)
Units: —
Precision: —
Error: throw ExecOverflowError("1202"); FORTRAN → ISTAT=1202
Deps: none
Frequency: on job creation (burns create many; overflow at PDI)
Determinism: deterministic (stable sort)
FORTRAN: SUBROUTINE NOVAC(IPRI,IPC,IJOB,ISTAT)
```

## 4. `Executive.longcall(delayCs, job)` / `Executive.tick(dtCs)`

```
Function: longcall / tick
Purpose: WAITLIST timed queue (T5) — DOCUMENTED pp.1117-1132
Inputs: delayCs INTEGER centiseconds, job; tick: dtCs
Outputs: waitlist sorted by time; tick moves due jobs to jobs[]
Mutation: waitlist, time
Frequency: tick 100 Hz; longcall per SERVIDR (2 s)
FORTRAN: SUBROUTINE LONGCL(IDLY,IJOB) / SUBROUTINE EXECTK(IDT)
```

## 5. Interpreter — `AgcInterpreter.exec(ops)`

```
Function: exec
Purpose: VM for DP vector ops (VLOAD/VSU/VAD/DOT/UNIT/ABVAL/VXM/EXIT) DOCUMENTED INTERPRETER.agc
Inputs: ops array {op,arg: Vec3/Mat3}, MPAC(7) REAL
Outputs: MPAC mutated, stack push/pop
Mutation: MPAC, stack
Numerics: DOT = Σ a_i b_i; UNIT = v/|v|; VXM = v^T M (row-major); ABVAL = |v|
Units: meters / m/s (scaled per FIXED constants; modern TS uses JS number — INFERRED scale)
Precision: TS=64-bit float; FORTRAN=DOUBLE PRECISION (approx); original DP=28-bit 1's complement → approximation labeled APPROXIMATION
Deps: none
Frequency: per Servicer guidance equation
FORTRAN: SUBROUTINE INTPRC(NOPS, IOPS, ARGS, MPAC7)  — DP via DOUBLE, UNIT guards |v|=0
```

## 6. `PhysicsEngine.step(dtMs)`

```
Function: step
Purpose: Integrate vehicle dynamics + Servicer 2-s cycle
Inputs: state {position Vec3 m, velocity Vec3 m/s, massKg REAL, dryMassKg, propulsion {thrustN, ispS, throttle}}; dtMs REAL ms
Outputs: state' position/velocity/mass
Mutation: state; tMs, servicerAccum
Side effects: none (servicerTick is internal)
Numerics: velocity[2]+= (thrust/mass)*dt - g*0.1*dt; mass -= thrust/(isp*9.80665)*dt; position+=velocity*dt (Euler, MODERN RECONSTRUCTION — not flight-accurate)
Units: SI (m, m/s, kg, N, s)
Precision: TS float64; FORTRAN DOUBLE
Error: clamp mass to dryMass
Deps: none (simplified; real orbital perturbations via orbital.ts)
Frequency: 1000 Hz minor cycle; Servicer 0.5 Hz
Determinism: deterministic (fixed dt, no Math.random)
FORTRAN: SUBROUTINE ENGSTP(DT, IERR)
  COMMON /VEHST/ ... /PHYSCF/DTMS, ISRVAC
```

## 7. `conicPropagate(r,v,dt,mu)`

```
Function: conicPropagate
Purpose: Kepler coast (f/g series stub) — DOCUMENTED CONIC_SUBROUTINES
Inputs: r Vec3 m, v Vec3 m/s, dt REAL s, mu REAL m3/s2
Outputs: {r:Vec3, v:Vec3}
Mutation: none
Numerics: stub: r' = r + v*dt (INFERRED: real Luminary uses universal variable — preserved as stub; FORTRAN preserves same stub for equivalence, labeled APPROXIMATION)
Units: SI
Precision: DOUBLE
Deps: none
FORTRAN: SUBROUTINE CONICP(R,V,DT,XMU,ROUT,VOUT)
```

## 8. `throttleCommand(aCmd, fc, mass)`

```
Function: throttleCommand
Purpose: DPS throttle from commanded acceleration — DOCUMENTED THROTTLE_CONTROL_ROUTINES 793-797
Inputs: aCmd REAL m/s2, fc REAL N/kg (or 0 to compute), mass REAL kg
Outputs: throttle REAL 0.10..0.94
Mutation: none
Numerics: fcEff = fc or thrust/mass (45000/mass); throttle=|aCmd|/fcEff clamped [0.10,0.94] (ENGINES.DPS)
Units: m/s2, N/kg
Precision: REAL
Deps: ENGINES.DPS (45000 N, throttle range)
Frequency: Servicer 0.5 Hz
FORTRAN: REAL FUNCTION THROTC(ACMD, FC, AMASS)
```

## 9. `dapStep(current, desired, dt)`

```
Function: dapStep
Purpose: Digital Autopilot phase-plane stub — DOCUMENTED P/Q-R-AXIS + TJET_LAW
Inputs: current Attitude{roll,pitch,yaw,rate(3)}, desired Attitude, dt REAL
Outputs: {jets STRING[], gimbal[2] REAL}
Mutation: none
Numerics: PD with deadband 0.3° / 0.3°/s (DOCUMENTED); jets selected if |err|>DB or |rate|>RDB; gimbal = err*0.01
Units: degrees
Precision: REAL
FORTRAN: SUBROUTINE DAPSTP(CUR, DES, DT, JETS, NG, GIMB)
  Jets encoded as INTEGER flags (bit mask), gimbal REAL*8
```

## 10. `State` + `metToString` / `stringToMet`

```
Type: State
Purpose: Canonical mission state (see 04_CANONICAL_STATE)
Fields: metSeconds INTEGER, met STRING "000:00:00", vehicle INTEGER flag, guidanceMode INTEGER, propulsion {engine INTEGER flag, thrustN REAL, ispS REAL, throttle REAL, engOn INTEGER flag}, comms INTEGER, position REAL(3), velocity REAL(3), massKg REAL, dryMassKg REAL, cdu REAL(3), alarm INTEGER flag
FORTRAN: COMMON /MSTATE/ + 04 spec; met STRING → INTEGER IMET(3) hours/min/sec
Functions string↔seconds: purely presentation; FORTRAN helper ITOMET/IMTSEC
```

## 11. `loadTimeline` / `eventsToStates`

```
Function: loadTimeline + eventsToStates
Purpose: Ingest deterministic 22-event mission dataset (RECONSTRUCTED NASA Mission Report)
Inputs: path STRING → JSON {events: TimelineEvent[]}
Outputs: State[] (pos/vel zeroed, mass 15000, dry 4000, thrust flags per phase)
Mutation: none
Side effects: file read (I/O)
Numerics: MET string → seconds via split; vehicle/guidance mapping via string compare (MODERN CONVENIENCE)
Units: seconds
FORTRAN: SUBROUTINE LDTIML(FNAME, N, IERR) reading fixed-format file (see 11_REPLAY_FORMAT); mapping via INTEGER code tables
```

## 12. `DeterministicReplay.step()` / `replayAll()` / `canonical()`

```
Function: step
Purpose: Emit one mission event as State + TelemetryFrame + hash (MODERN DESIGN)
Inputs: states[22], cursor INTEGER, hash STRING hex
Outputs: ReplayFrame {state, telemetry, crewProc, hash} and mutated hash/cursor/log
Mutation: cursor, hash, log
Numerics: canonical = JSON sorted keys + toFixed(2) (MODERN); hash = SHA256(prev+canonical) (MODERN); FORTRAN replaces with INTEGER checksum
Units: —
Precision: 2 decimal places in canonical (TS)
Deps: buildFrame, wordsFromState, MsfNetwork
Frequency: per event (22 total) — not per physics tick
Determinism: deterministic if hash replaced deterministically
FORTRAN: SUBROUTINE REPSTP(IFRAME, IERR) / SUBROUTINE REPRUN(N, IERR); ICHFNC replaces SHA256 with MOD checksum

Function: verifyDeterminism()
Purpose: Run replay twice, compare final hash — deterministic proof
FORTRAN: SUBROUTINE REPVFY(IMATCH)
```

## 13. `buildFrame` / `downlink` hash chain

```
Function: buildFrame(state,listId,words)
Purpose: Assemble telemetry frame with sync word and hash chain (DOWNLINK_LISTS DOCUMENTED + MODERN hash)
Inputs: state, listId 0..5, words {addrOct,symbol,valueOct,valueDec}[]
Outputs: TelemetryFrame {met,metSeconds,listId,listName,syncWord=0x7776,hashChain{prev,frame,algo=SHA256}}
Mutation: module prevHash
Numerics: frameHash=SHA256(prev+JSON(words)) — MODERN; FORTRAN → INTEGER*4 checksum MOD 2^31
Deps: crypto
FORTRAN: SUBROUTINE BFRAME(IMET, ILIST, NWORDS, WORDS, IHASH, IERR)
```

## 14. `CommsLink.update(signalDb)`

```
Function: update
Purpose: MSFN state machine ACQUIRE→LOCK→DATA→DROP (RECONSTRUCTED)
Inputs: signalDb REAL dB
Outputs: state CommsState
Mutation: state, signalDb
Numerics: thresholds -90, -85, -100 dB
FORTRAN: SUBROUTINE COMUPD(IIDX, SIGDB, ISTATE, IERR)
  COMMON /COMMS/ ISTATE(3), SIGDB(3)
```

## 15. `FaultInjector.inject(spec,replay)`

```
Function: inject
Purpose: Inject executive overflow / comm drop / thrust stuck / IMU drift (MODERN)
Inputs: spec {kind INTEGER flag, atMet STRING, durationS, magnitude}, replay, exec
Outputs: side effect on Executive/State (10× novac at 6 to overflow)
Mutation: Executive.jobs
Deps: Executive.novac
FORTRAN: SUBROUTINE FLTINS(IKIND, IMET, AMAG, IERR)
```

## 16. `assertInvariant(s)`

```
Function: assertInvariant
Purpose: Runtime check of formal properties per docs/FORMAL_VERIFICATION.md:5
Inputs: State
Outputs: throw InvariantViolation if violated
Mutation: none
Numerics: throttle ∈[0.10,0.94] if P63/P64; mass≥dry; comms/no-skip checked elsewhere
FORTRAN: SUBROUTINE ASSINV(IERR)  IERR=0 ok, 1=throttle, 2=mass
```

All contracts above are the **source spec** for `fortran1978/*.f`; any unspecified modern behavior (e.g., JSON field order, SHA hex) is explicitly marked APPROXIMATION or MODERN CONVENIENCE and replaced with deterministic FORTRAN equivalent per mapping matrix.
