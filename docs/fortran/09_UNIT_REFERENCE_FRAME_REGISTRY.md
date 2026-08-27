# Unit & Reference-Frame Registry

> Per Phase 6 — record coordinate systems, reference frames, units, time systems, integration, trig, matrix/vector ordering, sign conventions. Any INFERRED where TS underspecified.

| Aspect | TS Convention | FORTRAN | Notes |
|--------|---------------|---------|-------|
| **Coordinate system** | `position: [x,y,z]` ECI placeholder (engine.ts) / LCL (Implied lunar) — not labeled per phase in TS stub | `POS(3)` REAL*8 — same ordering X=1,Y=2,Z=3; frame flag `IFRAME=0 Earth 1 Moon` (added for clarity, INFERRED) | Original Luminary uses REFSMMAT + stable member; modern TS stub omits — preserved as stub; differential tests compare vectors directly, not frame transforms |
| **Reference frame** | Inertial (quasi-ECI) — TS Euler does not rotate frames | `COMMON /REFSYS/ IFRAME` | Labeled INFERRED where not per-phase; not improved to full ECI↔Moon |
| **Units — length** | meters (`orbital.ts:7`, `engine.ts:23`) | `REAL*8` meters | SI |
| **Units — time** | seconds `metSeconds`, milliseconds `dtMs`, centiseconds `waitlist` | `INTEGER IMETSC` seconds; `REAL*8 DT` seconds; `INTEGER IDTMS` ms | SI; conversion `DT = DTMS/1000.D0` |
| **Units — mass** | kg `massKg` | `REAL*8 AMASS` kg | SI |
| **Units — thrust** | N `thrustN` | `REAL*8 THRUST` N | SI (1 lbf =4.44822 N) |
| **Units — Isp** | seconds | `REAL*8 ISP` s |  |
| **Units — angles** | degrees `cdu` `DEADBAND` | `REAL*8 CDU(3)` degrees | DAP uses deg, not rad |
| **Units — rates** | deg/s | `REAL*8 RATE(3)` |  |
| **Time system** | MET seconds from liftoff `000:00:00` canonical | `IMETSC` + `CMET*8` | No UTC/TAI conversion; timeline loader computes `IMETSC = H*3600+M*60+S` |
| **Integration method** | Explicit Euler `pos+=vel*dt` `engine.ts:27` | `POS(I)=POS(I)+VEL(I)*DT` loop | Euler preserved (not upgraded to RK4) — APPROXIMATION flagged |
| **Constants** | See `08_NUMERICAL_CONSTANTS_REGISTRY` | Same `XMU_MOON` etc. |  |
| **Precision** | TS `number` IEEE 64 (~15 dec digits) | `REAL*8` / `DOUBLE PRECISION` | Equivalent; `INTEGER` for words |
| **Rounding** | `toFixed(2)` in `deterministic.ts:25` canonical | `FORMAT(F8.2)` | Same half-away (FORTRAN) ≈ TS (tie handling negligible vs tolerance 1e-6) |
| **Trig conventions** | `Math.hypot` → `UNIT` | `DSQRT/SIN/COS` | Arguments in radians; DAP thresholds in deg convert via `*PI/180` only where needed (not in deadband — deg compare direct) |
| **Matrix ordering** | `VXM: v^T M` row-major `interpreter.ts:10` `v[0]*m[0][0]+v[1]*m[1][0]...` | `M(3,3)` column-major FORTRAN but accessed transposed to preserve math: `VXM = V(1)*M(1,1)+V(2)*M(1,2)...` | Labeled INFERRED — ensure test vector `VXM([1,0,0], Identity)=[1,0,0]` passes both |
| **Vector ordering** | `[x,y,z]` index 0,1,2 | `(1,2,3)` 1-indexed | Offset by 1; differential harness accounts |
| **Sign conventions** | Thrust +Z local `engine.ts:19` comment; gravity -Z | `VEL(3)=VEL(3)+ THRUST/AMASS*DT - G*0.1*DT` | Preserved (stub) |
| **Endianness / word** | 1's complement oct `077777` | `IAND(077777)` masking | Identical bitwise |

## INFERRED Gaps Surfaced (blocks numerical port until resolved — now resolved as stubs)

- **Original issue:** `engine.ts:23` gravity `g0*0.1` factor unexplained → preserved as `GMOON*0.1` in `engine.f` with comment "INFERRED stub from TS — not flight g model"
- **Original issue:** Frame switch at 5e6 m `orbital.ts:15` crude `if hypot<5e6 moon else earth` → preserved as `IF (RMAG.LT.5.0D6) XMU=XMU_MOON` in `orbital.f`

Both now **portable** because stubs are deterministic and documented as APPROXIMATION.

## Verification

Differential tests compare `POS/VEL` with tolerance `1e-6` m / `1e-9` m/s for Euler steps (stub); frame flag compared exact.
